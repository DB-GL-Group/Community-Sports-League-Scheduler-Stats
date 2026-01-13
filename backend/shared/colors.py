import string

DEFAULT_COLOR = "#9E9E9E"

_NAMED_COLORS = {
    "red": "#D32F2F",
    "blue": "#1976D2",
    "green": "#388E3C",
    "yellow": "#FBC02D",
    "orange": "#F57C00",
    "purple": "#7B1FA2",
    "black": "#212121",
    "white": "#FFFFFF",
    "grey": "#616161",
    "gray": "#616161",
    "lightgrey": "#E0E0E0",
    "lightgray": "#E0E0E0",
}


def normalize_color(value: str | None) -> str | None:
    if not value:
        return None
    cleaned = value.strip()
    if not cleaned:
        return None
    lowered = cleaned.lower()
    if lowered in _NAMED_COLORS:
        return _NAMED_COLORS[lowered]
    if cleaned.startswith("#"):
        cleaned = cleaned[1:]
    if len(cleaned) != 6:
        return None
    if not all(ch in string.hexdigits for ch in cleaned):
        return None
    return f"#{cleaned.upper()}"
