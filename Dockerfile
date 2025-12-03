# Haley - ERPNext v16 + Enhanced Kanban View
# Zero-downtime deployment image

FROM frappe/erpnext:v16

# Copy enhanced_kanban_view app with correct ownership
COPY --chown=frappe:frappe apps/enhanced_kanban_view /home/frappe/frappe-bench/apps/enhanced_kanban_view

# Copy custom assets (logo, theme)
COPY --chown=frappe:frappe assets/haley-logo.png /home/frappe/frappe-bench/sites/assets/haley-logo.png
COPY --chown=frappe:frappe assets/haley-theme.css /home/frappe/frappe-bench/sites/assets/haley-theme.css

# Install the app properly using bench's virtual environment
# Note: bench build runs at deploy time after site exists
RUN cd /home/frappe/frappe-bench && \
    echo "" >> sites/apps.txt && \
    echo "enhanced_kanban_view" >> sites/apps.txt && \
    /home/frappe/frappe-bench/env/bin/pip install -e apps/enhanced_kanban_view
