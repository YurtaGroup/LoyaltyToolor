"""add finik payment fields

Revision ID: a2c3d4e5f6g7
Revises: f571aabd609e
Create Date: 2026-03-29 18:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'a2c3d4e5f6g7'
down_revision: Union[str, None] = 'f571aabd609e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('orders', sa.Column('payment_transaction_id', sa.String(), nullable=True))
    op.add_column('orders', sa.Column('payment_provider', sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column('orders', 'payment_provider')
    op.drop_column('orders', 'payment_transaction_id')
