from django.urls import path

from .views import (CollectFacebookView, CollectGoogleMapsView,
                    CollectYouTubeView, GooglePlacePhotoProxyView,
                    IngestJobListView, RawRecordListView)

urlpatterns = [
    path(
        "collect/youtube/", CollectYouTubeView.as_view(), name="datahub-collect-youtube"
    ),
    path(
        "collect/facebook/",
        CollectFacebookView.as_view(),
        name="datahub-collect-facebook",
    ),
    path(
        "collect/google-maps/",
        CollectGoogleMapsView.as_view(),
        name="datahub-collect-google-maps",
    ),
    path(
        "google-place-photo/",
        GooglePlacePhotoProxyView.as_view(),
        name="datahub-google-place-photo-proxy",
    ),
    path("records/", RawRecordListView.as_view(), name="datahub-records"),
    path("jobs/", IngestJobListView.as_view(), name="datahub-jobs"),
]
