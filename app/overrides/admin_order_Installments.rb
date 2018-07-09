Deface::Override.new(
    virtual_path: 'spree/admin/shared/_order_tabs',
    name: 'admin_orders_installment',
    insert_bottom: "[data-hook='admin_order_tabs']",
    text: '
      <li<%== " class=\'active\'" if current == :installments %> data-hook="admin_order_tabs_installments">
        <a class="icon-link with-tip" href="<%= spree.admin_orders_installments_url(@order) %>">
          <span class="icon glyphicon-th-list"></span>
          <span class="text">Installments</span>
        </a>
      </li>
  '
  )
  