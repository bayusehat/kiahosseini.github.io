from copy import deepcopy

from django import forms
from django.conf import settings
from django.utils.translation import get_language


class ValidateForm(object):

    @property
    def media(self):
        # I don't use class Media, because I need current_language in path
        return super(ValidateForm, self).media + forms.Media(
            js=('{}form_validation/jquery/jquery.validate.min.js'.format(
                    settings.STATIC_URL),
                ('{}form_validation/jquery/' +
                    'jquery.validate.messages.{}.js').format(
                    settings.STATIC_URL, get_language()),
                '{}form_validation/js/our_base_form.js'.format(
                    settings.STATIC_URL),
                ),
            css={'all': ('{}form_validation/jquery/jquery.validate.css'.format(
                            settings.STATIC_URL))})

    validation_required_fields = []
    validation_max_length_fields = {}
    validation_min_length_fields = {}
    validation_equals_fields = {}
    validation_regex_fields = []
    validation_email_fields = []
    validation_url_fields = []
    validation_digits_fields = []
    validation_number_fields = []
    validation_date_fields = []

    required_css_class = 'required'

    def __init__(self, *args, **kwargs):
        super(ValidateForm, self).__init__(*args, **kwargs)
        if hasattr(self, 'fields'):
            ValidateForm.get_ready_for_validation(form_instance=self)

    @staticmethod
    def get_ready_for_validation(form_instance):
        required_fields = deepcopy(form_instance.validation_required_fields)
        max_length_fields = deepcopy(
            form_instance.validation_max_length_fields)
        equals_fields = deepcopy(form_instance.validation_equals_fields)
        min_length_fields = deepcopy(
            form_instance.validation_min_length_fields)
        regex_fields = deepcopy(form_instance.validation_regex_fields)
        email_fields = deepcopy(form_instance.validation_email_fields)
        url_fields = deepcopy(form_instance.validation_url_fields)
        digits_fields = deepcopy(form_instance.validation_digits_fields)
        number_fields = deepcopy(form_instance.validation_number_fields)
        date_fields = deepcopy(form_instance.validation_date_fields)

        for f in form_instance.fields.keys():
            fld = form_instance.fields[f]
            if hasattr(form_instance, 'Meta') and \
                    hasattr(form_instance.Meta, 'blank_fields'):
                if f not in form_instance.Meta.blank_fields and fld.required:
                    required_fields += [f]
            else:
                if fld.required:
                    required_fields += [f]
            if getattr(fld, 'max_length', False) and \
                    f not in max_length_fields:
                max_length_fields[f] = fld.max_length
            if getattr(fld, 'min_length', False) and \
                    f not in min_length_fields:
                min_length_fields[f] = fld.min_length
            if forms.EmailField in fld.__class__.__bases__ or \
                    isinstance(fld, forms.EmailField):
                email_fields += [f]
            if forms.URLField in fld.__class__.__bases__ or \
                    isinstance(fld, forms.URLField):
                url_fields += [f]
            if getattr(fld, 'digits', False):
                digits_fields += [f]
            if forms.FloatField in fld.__class__.__bases__ or \
                forms.IntegerField in fld.__class__.__bases__ or isinstance(
                    fld, (forms.IntegerField, forms.FloatField)) or \
                    getattr(fld, 'number', False):
                number_fields += [f]
        for f in form_instance.fields.keys():
            fld = form_instance.fields[f]
            if f in required_fields:
                fld.required = True
                fld.widget.attrs['required'] = True

            if f in max_length_fields.keys():
                fld.widget.attrs['maxlength'] = max_length_fields.get(f)

            if f in min_length_fields.keys():
                fld.widget.attrs['minlength'] = min_length_fields.get(f)

            if f in equals_fields.keys():
                prefix = ''
                if form_instance.prefix:
                    prefix = '_%s' % form_instance.prefix
                fld.widget.attrs['equalTo'] = '#id%s_%s' % (
                    prefix,
                    equals_fields.get(f))

            if f in email_fields:
                fld.widget.attrs['email'] = True

            if f in url_fields:
                fld.help_text += 'http://www.example.com'

            if f in digits_fields:
                fld.widget.attrs['digits'] = True

            if f in number_fields:
                fld.widget.attrs['number'] = True

            if forms.FileField in fld.__class__.__bases__ or \
                isinstance(fld, forms.FileField) or \
                    getattr(fld, 'content_types', False) or getattr(
                        fld, 'ext_whitelist', False):
                fld.widget.attrs['extension'] = ','.join(
                    getattr(fld, 'ext_whitelist', []))
                if f in required_fields and \
                    (hasattr(form_instance, 'instance') and
                        getattr(form_instance.instance, f, False)):
                    del fld.widget.attrs['required']

            if forms.ImageField in fld.__class__.__bases__ or \
                    isinstance(fld, forms.ImageField):
                fld.widget.attrs['accept'] = 'image/*'
                fld.widget.attrs['extension'] = 'jpg,jpeg,gif,png'

        ValidateForm.clear_lists(form_instance)

    @staticmethod
    def clear_lists(form_instance):
        form_instance.validation_max_length_fields = \
            form_instance.validation_min_length_fields = \
            validation_equals_fields = {}
        form_instance.validation_email_fields = \
            form_instance.validation_regex_fields = \
            form_instance.validation_required_fields = \
            form_instance.validation_url_fields = \
            form_instance.validation_digits_fields = []


class BaseForm(ValidateForm, forms.Form):
    pass


class BaseModelForm(ValidateForm, forms.ModelForm):
    pass
