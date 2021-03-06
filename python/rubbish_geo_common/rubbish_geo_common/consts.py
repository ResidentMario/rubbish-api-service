"""
Library constants.
"""

RUBBISH_TYPES = ['tobacco', 'paper', 'plastic', 'other', 'food', 'glass']
RUBBISH_TYPE_MAP = {v: i for i, v in enumerate(RUBBISH_TYPES)}

__all__ = ['RUBBISH_TYPES', 'RUBBISH_TYPE_MAP']
