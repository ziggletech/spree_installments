Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  get  '/captureinstalment/:id' => 'admin/orders#captureInstalment', as: 'admin_orders_captureInstalment' 
end
