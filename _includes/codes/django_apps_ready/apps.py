from django.apps import AppConfig
from django.db.models.signals import pre_save
from .signal_receivers import post_pre_save_receiver


class BlogConfig(AppConfig):
    name = 'blog'
    verbose_name = "My Blog App"

    def ready(self):
        from .models import Post  # importing model classes directly
        PostModel = self.get_model('Post')  # or using the get_model method

        # Here you can do what you like with your model safely.

        # registering signals with the model's string label
        pre_save.connect(post_pre_save_receiver,
                         sender='blog.Post')
