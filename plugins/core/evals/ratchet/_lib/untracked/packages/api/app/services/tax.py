RATES = {"US": 0.0, "DE": 0.19}


def rate_for(country, default=None):  # noqa: B008
    return RATES.get(country, default)  # noqa
