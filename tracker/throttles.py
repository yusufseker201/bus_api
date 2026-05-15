from rest_framework.throttling import SimpleRateThrottle


class UserReportRateThrottle(SimpleRateThrottle):
    """
    Allow at most three report submissions per hour per authenticated user.
    """

    scope = 'user_report'
    rate = '3/hour'

    def get_cache_key(self, request, view):
        user = getattr(request, 'user', None)
        if user is None or not user.is_authenticated:
            return None

        return self.cache_format % {
            'scope': self.scope,
            'ident': f'user-{user.pk}',
        }
