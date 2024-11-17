# Use datagrid_form_with
git grep 'datagrid_form_for'

# Inline content of datagrid/order_for partial
git grep 'datagrid_order_for'

# Put necessary classes manually
# or copy the helper from datagrid source code to ApplicationHelper
git grep 'datagrid_column_classes' 

# Inherit Datagrid::Base
git grep 'include Datagrid' 

# Use rails g datagrid:views
git grep 'datagrid:copy_partials'

# Rename to ApplicationGrid (optional)
git grep 'BaseDatagrid'
git grep 'BaseGrid'

# Use choices instead
git grep 'elements' app/views/datagrid/_enum_checkboxes.*

# Use datagrid_filter_input instead
git grep 'check_box' app/views/datagrid/_enum_checkboxes.*
