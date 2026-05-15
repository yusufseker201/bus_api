class DevelopmentCorsMiddleware:
    """
    Minimal CORS support for local Flutter web development.

    This allows `flutter run -d chrome` on localhost to call the Django API
    on port 8000 without pulling in an extra dependency.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.method == 'OPTIONS':
            response = self._preflight_response()
        else:
            response = self.get_response(request)

        origin = request.headers.get('Origin')
        if self._is_allowed_origin(origin):
            response['Access-Control-Allow-Origin'] = origin
            response['Vary'] = 'Origin'
            response['Access-Control-Allow-Credentials'] = 'true'
            response['Access-Control-Allow-Headers'] = 'Authorization, Content-Type'
            response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'

        return response

    def _preflight_response(self):
        from django.http import HttpResponse

        return HttpResponse(status=204)

    def _is_allowed_origin(self, origin):
        if not origin:
            return False

        return (
            origin.startswith('http://localhost:')
            or origin.startswith('http://127.0.0.1:')
            or origin == 'http://localhost'
            or origin == 'http://127.0.0.1'
        )
