"""add apple_id and google_id to profiles

Revision ID: c4e5f6g7h8i9
Revises: b3d4e5f6g7h8
Create Date: 2026-03-31 18:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "c4e5f6g7h8i9"
down_revision: Union[str, None] = "b3d4e5f6g7h8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("profiles", sa.Column("apple_id", sa.String(), nullable=True))
    op.add_column("profiles", sa.Column("google_id", sa.String(), nullable=True))
    op.create_unique_constraint("uq_profiles_apple_id", "profiles", ["apple_id"])
    op.create_unique_constraint("uq_profiles_google_id", "profiles", ["google_id"])
    # Make phone nullable for OAuth-only users
    op.alter_column("profiles", "phone", existing_type=sa.String(), nullable=True)
    # Make password_hash have a default for OAuth users
    op.alter_column(
        "profiles",
        "password_hash",
        existing_type=sa.String(),
        server_default="",
        nullable=False,
    )


def downgrade() -> None:
    op.alter_column("profiles", "password_hash", server_default=None)
    op.alter_column("profiles", "phone", existing_type=sa.String(), nullable=False)
    op.drop_constraint("uq_profiles_google_id", "profiles", type_="unique")
    op.drop_constraint("uq_profiles_apple_id", "profiles", type_="unique")
    op.drop_column("profiles", "google_id")
    op.drop_column("profiles", "apple_id")
