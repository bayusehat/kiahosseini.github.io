from django.contrib.admin import ModelAdmin
from .forms import ValidateForm


def attach_our_base_form(fn):
    def get_form(self, *args, **kwargs):
        form = fn(self, *args, **kwargs)
        setattr(form, '__init__', attach_validate_init(form.__init__))
        return form

    setattr(get_form, 'our_get_form', True)
    return get_form


def attach_validate_init(fn):
    def init(self, *args, **kwargs):
        if ValidateForm not in self.__class__.__bases__:
            self.__class__.__bases__ = (ValidateForm,) + \
                self.__class__.__bases__
        fn(self, *args, **kwargs)
        ValidateForm.get_ready_for_validation(form_instance=self)

    return init


if not hasattr(ModelAdmin.get_form, 'our_get_form'):
    setattr(ModelAdmin, 'get_form', attach_our_base_form(ModelAdmin.get_form))
