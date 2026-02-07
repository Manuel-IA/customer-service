Customer.delete_all

# PostgreSQL reset so that the IDs start again at 1
if ActiveRecord::Base.connection.adapter_name.downcase.include?("postgres")
  ActiveRecord::Base.connection.reset_pk_sequence!("customers")
end

customers = [
  { customer_name: "Ana Gómez",        address: "Cra 7 # 32-16, Bogotá",         orders_count: 0 },
  { customer_name: "Carlos Ramírez",   address: "Cl 80 # 12-34, Bogotá",         orders_count: 0 },
  { customer_name: "Luisa Fernanda",   address: "Av 19 # 100-20, Bogotá",        orders_count: 0 },
  { customer_name: "Mateo Torres",     address: "Cl 26 # 59-41, Bogotá",         orders_count: 0 },
  { customer_name: "Sofía Pérez",      address: "Cra 15 # 93-60, Bogotá",        orders_count: 0 },
  { customer_name: "Juan Pablo Díaz",  address: "Cl 45 # 9-12, Bogotá",          orders_count: 0 },
  { customer_name: "Valentina Rojas",  address: "Cra 30 # 10-25, Bogotá",        orders_count: 0 },
  { customer_name: "Sebastián López",  address: "Av Suba # 114-45, Bogotá",      orders_count: 0 },
  { customer_name: "Camila Herrera",   address: "Cra 11 # 72-30, Bogotá",        orders_count: 0 },
  { customer_name: "Andrés Martínez",  address: "Cl 13 # 4-21, Bogotá",          orders_count: 0 },
  { customer_name: "Diana Castillo",   address: "Cra 50 # 8-90, Bogotá",         orders_count: 0 },
  { customer_name: "Felipe Sánchez",   address: "Cl 127 # 7-19, Bogotá",         orders_count: 0 }
]

Customer.insert_all!(customers)
