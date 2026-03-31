"""rename tier values to Kyrgyz horse names

Revision ID: d5f6g7h8i9j0
Revises: c4e5f6g7h8i9
Create Date: 2026-03-31 23:00:00.000000
"""
from typing import Sequence, Union

from alembic import op

revision: str = "d5f6g7h8i9j0"
down_revision: Union[str, None] = "b3d4e5f6g7h8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Rename tier values: bronze→kulun, silver→tai, gold→kunan, platinum→at
    op.execute("UPDATE loyalty_accounts SET tier = 'kulun' WHERE tier = 'bronze'")
    op.execute("UPDATE loyalty_accounts SET tier = 'tai' WHERE tier = 'silver'")
    op.execute("UPDATE loyalty_accounts SET tier = 'kunan' WHERE tier = 'gold'")
    op.execute("UPDATE loyalty_accounts SET tier = 'at' WHERE tier = 'platinum'")

    # Update CHECK constraint if it exists
    op.execute("""
        ALTER TABLE loyalty_accounts DROP CONSTRAINT IF EXISTS loyalty_accounts_tier_check;
        ALTER TABLE loyalty_accounts ADD CONSTRAINT loyalty_accounts_tier_check
            CHECK (tier IN ('kulun', 'tai', 'kunan', 'at'));
    """)


def downgrade() -> None:
    op.execute("UPDATE loyalty_accounts SET tier = 'bronze' WHERE tier = 'kulun'")
    op.execute("UPDATE loyalty_accounts SET tier = 'silver' WHERE tier = 'tai'")
    op.execute("UPDATE loyalty_accounts SET tier = 'gold' WHERE tier = 'kunan'")
    op.execute("UPDATE loyalty_accounts SET tier = 'platinum' WHERE tier = 'at'")

    op.execute("""
        ALTER TABLE loyalty_accounts DROP CONSTRAINT IF EXISTS loyalty_accounts_tier_check;
        ALTER TABLE loyalty_accounts ADD CONSTRAINT loyalty_accounts_tier_check
            CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum'));
    """)
