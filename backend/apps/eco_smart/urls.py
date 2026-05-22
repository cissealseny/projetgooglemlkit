from django.urls import path

from .views import (EcoSmartCentersView, EcoSmartClassificationView,
                    EcoSmartClusterView, EcoSmartEstimationView,
                    EcoSmartMultimodalView, EcoSmartNlpView)

urlpatterns = [
    path("classify/", EcoSmartClassificationView.as_view(), name="eco-classify"),
    path("estimate/", EcoSmartEstimationView.as_view(), name="eco-estimate"),
    path("cluster/", EcoSmartClusterView.as_view(), name="eco-cluster"),
    path("nlp/", EcoSmartNlpView.as_view(), name="eco-nlp"),
    path("multimodal/", EcoSmartMultimodalView.as_view(), name="eco-multimodal"),
    path("centers/", EcoSmartCentersView.as_view(), name="eco-centers"),
]
