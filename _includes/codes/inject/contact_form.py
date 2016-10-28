from forms import BaseForm


class ContactForm(BaseForm):
    name = forms.CharField(label='Name')
    subject = forms.CharField(label='Subject')
    message = forms.TextField(label='Message')
    email = forms.EmailField(label='Email')

cf = ContactForm()
print cf
