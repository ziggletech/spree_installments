Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  get  '/captureinstalment/:id' => 'admin/orders#captureInstalment', as: 'admin_orders_captureInstalment' 
  get  '/captureallinstallments/:id' => 'admin/orders#captureAllInstallments', as: 'admin_orders_captureAllInstallments' 
  get  '/deleteinstalment/:id' => 'admin/orders#deleteInstalment', as: 'admin_orders_deleteInstalment' 
  get  '/editinstalment/:id' => 'admin/orders#editInstalment', as: 'admin_orders_editInstalment' 
  put '/instalmentupdate' => 'admin/orders#updateInstalment', as: 'admin_orders_updateInstalment' 
end
