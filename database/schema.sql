-- Drop tables if they exist
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS parts CASCADE;
DROP TABLE IF EXISTS options CASCADE;
DROP TABLE IF EXISTS option_values CASCADE;
DROP TABLE IF EXISTS part_variants CASCADE;
DROP TABLE IF EXISTS part_variant_option_values CASCADE;
DROP TABLE IF EXISTS part_variant_compatibilities CASCADE;
DROP TABLE IF EXISTS part_option_compatibilities CASCADE;
DROP TABLE IF EXISTS price_adjustments CASCADE;
DROP TABLE IF EXISTS product_builds CASCADE;
DROP TABLE IF EXISTS product_build_parts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS shopping_carts CASCADE;
DROP TABLE IF EXISTS shopping_cart_builds CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS order_product_builds CASCADE;
DROP TABLE IF EXISTS order_product_build_parts CASCADE;
DROP TABLE IF EXISTS order_price_adjustments CASCADE;

-- Drop ENUM types if they exist
DROP TYPE IF EXISTS rule_type_enum CASCADE; 
DROP TYPE IF EXISTS condition_type_enum CASCADE;

CREATE TYPE rule_type_enum AS ENUM ('INCLUDE', 'EXCLUDE');
CREATE TYPE condition_type_enum AS ENUM ('SOURCE', 'TARGET');

-- Products Table
-- To store top level prdoducts like 'Bicycle', 'Skateboard', etc.
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    product_key VARCHAR(50) NOT NULL UNIQUE, -- 'bicycle', 'skateboard', 'surfboard', etc.
    description TEXT,
    active BOOLEAN DEFAULT TRUE,
    display_order INT DEFAULT 0, -- to control the order of products in the UI
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_active_and_key ON products(active, product_key);
CREATE INDEX idx_products_active_in_display_order ON products(active, display_order);

-- Parts Table
-- To store the parts of a product like 'frame', 'wheels', 'chain', etc.
CREATE TABLE parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    part_key VARCHAR(50) NOT NULL, -- 'frame', 'wheels', 'chain', etc.  scoped to a product
    name VARCHAR(100) NOT NULL,
    description TEXT,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, part_key)
);

CREATE INDEX idx_parts_display_order ON parts(display_order);
CREATE UNIQUE INDEX unique_part_key ON parts(product_id, part_key);
CREATE INDEX fk_parts_product_id ON parts(product_id);

-- Options Table
-- To store the options of a part like 'type', 'size', 'color', etc.
CREATE TABLE options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    part_id UUID NOT NULL REFERENCES parts(id) ON DELETE CASCADE,
    option_key VARCHAR(50) NOT NULL, -- 'type', 'size', 'color', etc.
    name VARCHAR(100) NOT NULL,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(part_id, option_key)
);

CREATE INDEX idx_options_display_order ON options(display_order);
CREATE UNIQUE INDEX unique_option_key ON options(part_id, option_key);
CREATE INDEX fk_options_part_id ON options(part_id);


-- Part Option Values Table
-- To store the values of an option like 'full-suspension', '29-inch', 'red', etc.
CREATE TABLE option_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    option_id UUID NOT NULL REFERENCES options(id) ON DELETE CASCADE,
    value VARCHAR(255) NOT NULL,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(option_id, value)
);

CREATE INDEX idx_option_values_display_order ON option_values(display_order);
CREATE UNIQUE INDEX unique_option_value_key ON option_values(option_id, value);
CREATE INDEX fk_option_values_option_id ON option_values(option_id);


-- Part Variants Table
-- To store the complete configurations like "29-inch wheel with red rim"
CREATE TABLE part_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    part_id UUID NOT NULL REFERENCES parts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE, -- slight denormalization to avoid N+1 queries in compatibility service
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    in_stock BOOLEAN DEFAULT TRUE,
    active BOOLEAN DEFAULT TRUE,
    sku VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_part_variants_active_in_stock ON part_variants(active, in_stock);
CREATE INDEX fk_part_variants_product_id ON part_variants(product_id);
-- ideally we would have a unique SKU for every variant, but given different manufacturers, it's not always possible, so 
-- at least we can ensure that the SKU is unique for a given part
CREATE UNIQUE INDEX unique_part_variant_sku_and_part_id ON part_variants(part_id, sku) WHERE sku IS NOT NULL;
CREATE INDEX fk_part_variants_part_id ON part_variants(part_id);

-- Join table to store the option values for a part variant
CREATE TABLE part_variant_option_values (
    part_variant_id UUID NOT NULL REFERENCES part_variants(id) ON DELETE CASCADE,
    option_value_id UUID NOT NULL REFERENCES option_values(id) ON DELETE CASCADE,
    PRIMARY KEY (part_variant_id, option_value_id)
);

CREATE INDEX fk_part_variant_option_values_part_variant_id ON part_variant_option_values(part_variant_id);
CREATE INDEX fk_part_variant_option_values_option_value_id ON part_variant_option_values(option_value_id);


-- Part Variant Compatibility Table
-- To store the compatibility rules between part variants (one to one match)
CREATE TABLE part_variant_compatibilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE, -- scope to a product at database level
    part_variant_1_id UUID NOT NULL REFERENCES part_variants(id) ON DELETE CASCADE,
    part_variant_2_id UUID NOT NULL REFERENCES part_variants(id) ON DELETE CASCADE,
    compatibility_type rule_type_enum NOT NULL DEFAULT 'INCLUDE', -- so we can INCLUDE or EXCLUDE a pair of variants 
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT variant_ids_ordered CHECK (part_variant_1_id < part_variant_2_id), -- the rules are bidirectional, so we only need to store one direction
    UNIQUE(part_variant_1_id, part_variant_2_id)
);

CREATE INDEX fk_part_variant_compatibilities_product_id ON part_variant_compatibilities(product_id);
CREATE INDEX fk_part_variant_compatibilities_part_variant_1_id ON part_variant_compatibilities(part_variant_1_id);
CREATE INDEX fk_part_variant_compatibilities_part_variant_2_id ON part_variant_compatibilities(part_variant_2_id);
CREATE INDEX idx_part_variant_compatibilities_active ON part_variant_compatibilities(active);



-- Part Option Compatibility Table
-- To store the compatibility rules between parts using option values (many to many match)
-- E.i. 'Mountain (option value) bikes' are compatible with 'Full-suspension (option value) frames'
CREATE TABLE part_option_compatibilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    option_value_1_id UUID NOT NULL REFERENCES option_values(id) ON DELETE CASCADE,
    option_value_2_id UUID NOT NULL REFERENCES option_values(id) ON DELETE CASCADE,
    compatibility_type rule_type_enum NOT NULL DEFAULT 'INCLUDE',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT part_option_value_ids_ordered CHECK (option_value_1_id < option_value_2_id),
    UNIQUE(option_value_1_id, option_value_2_id)
);

CREATE INDEX fk_part_option_compatibilities_product_id ON part_option_compatibilities(product_id);
CREATE INDEX fk_part_option_compatibilities_option_value_1_id ON part_option_compatibilities(option_value_1_id);
CREATE INDEX fk_part_option_compatibilities_option_value_2_id ON part_option_compatibilities(option_value_2_id);
CREATE INDEX idx_part_option_compatibilities_active ON part_option_compatibilities(active);
CREATE UNIQUE INDEX unique_part_option_compatibility ON part_option_compatibilities(option_value_1_id, option_value_2_id);

-- Price Adjustments Table
-- To store pricing rules between parts using option values (many to many match)
-- I.i. A combination of 'Diamond frame' and 'Matte Finish' costs extra 15 EUR
CREATE TABLE price_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    option_value_1_id UUID NOT NULL REFERENCES option_values(id) ON DELETE CASCADE,
    option_value_2_id UUID NOT NULL REFERENCES option_values(id) ON DELETE CASCADE,
    price_adjustment DECIMAL(10,2) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT price_adjustments_option_value_ids_ordered CHECK (option_value_1_id < option_value_2_id),
    UNIQUE(option_value_1_id, option_value_2_id)
);

CREATE INDEX fk_price_adjustments_product_id ON price_adjustments(product_id);
CREATE INDEX fk_price_adjustments_option_value_1_id ON price_adjustments(option_value_1_id);
CREATE INDEX fk_price_adjustments_option_value_2_id ON price_adjustments(option_value_2_id);
CREATE UNIQUE INDEX unique_price_adjustment ON price_adjustments(option_value_1_id, option_value_2_id);
CREATE INDEX idx_price_adjustments_active ON price_adjustments(active);

-- Customers Table
-- Simplified table to represent customers
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_customers_email ON customers(email);

-- Product Builds Table
-- To store the builds of a product so we can track progress, share with customers, etc.
CREATE TABLE product_builds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL, -- NULL for guest builds
    name VARCHAR(255),
    is_completed BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_product_builds_is_completed_and_featured ON product_builds(is_completed, is_featured, updated_at DESC);
CREATE INDEX fk_product_builds_product_id ON product_builds(product_id);
CREATE INDEX fk_product_builds_customer_id ON product_builds(customer_id);

-- Join table to store the parts of a build
CREATE TABLE product_build_parts (
    build_id UUID NOT NULL REFERENCES product_builds(id) ON DELETE CASCADE,
    part_variant_id UUID NOT NULL REFERENCES part_variants(id) ON DELETE CASCADE,
    PRIMARY KEY (build_id, part_variant_id)
);

CREATE INDEX fk_product_build_parts_build_id ON product_build_parts(build_id);
CREATE INDEX fk_product_build_parts_part_variant_id ON product_build_parts(part_variant_id);

-- Shopping Carts Table
-- To store carts for guests and registered customers
CREATE TABLE shopping_carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE, -- NULL for guest carts
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add a partial unique index to ensure unique carts for registered customers
CREATE UNIQUE INDEX unique_customer_cart ON shopping_carts(customer_id) WHERE customer_id IS NOT NULL;



-- Join table to store the builds of a cart
-- One day me might want to add a different join table to have parts outside of builds in the carts (like accessories)
CREATE TABLE shopping_cart_builds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shopping_cart_id UUID NOT NULL REFERENCES shopping_carts(id) ON DELETE CASCADE,
    build_id UUID NOT NULL REFERENCES product_builds(id) ON DELETE CASCADE,
    quantity INT DEFAULT 1,
    UNIQUE(shopping_cart_id, build_id)
);

CREATE INDEX fk_shopping_cart_builds_shopping_cart_id ON shopping_cart_builds(shopping_cart_id);
CREATE INDEX fk_shopping_cart_builds_build_id ON shopping_cart_builds(build_id);
CREATE UNIQUE INDEX unique_shopping_cart_build ON shopping_cart_builds(shopping_cart_id, build_id);


-- Orders Table
-- To store the orders of a customer
-- Customer information like shipping address, payment details, etc are simplified
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    order_number VARCHAR(50) NOT NULL UNIQUE, -- human readable order/invoice number
    status VARCHAR(50) NOT NULL, -- 'pending', 'processing', 'shipped', 'delivered', 'cancelled'
    total_amount DECIMAL(10,2) NOT NULL,
    shipping_address VARCHAR(255) NOT NULL,
    customer_comments TEXT,
    payment_method VARCHAR(100),
    payment_status VARCHAR(50), -- 'pending', 'paid', 'refunded'
    shop_comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(order_number)
);

CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX fk_orders_customer_id ON orders(customer_id);
CREATE UNIQUE INDEX unique_order_number ON orders(order_number);

-- Order Product Builds Table
-- To have records of the builds details that customer ordered at the time of order
CREATE TABLE order_product_builds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    build_id UUID REFERENCES product_builds(id) ON DELETE SET NULL,
    build_name VARCHAR(255), -- Copy at time of order
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    product_name VARCHAR(255), -- Copy at time of order
    quantity INT DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,  -- Unit Price at time of order
    total_price DECIMAL(10, 2) NOT NULL, -- total Price at time of order
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX unique_order_build ON order_product_builds(order_id, build_id) WHERE build_id IS NOT NULL;
CREATE INDEX fk_order_product_builds_order_id ON order_product_builds(order_id);
CREATE INDEX fk_order_product_builds_build_id ON order_product_builds(build_id);
CREATE INDEX fk_order_product_builds_product_id ON order_product_builds(product_id);

-- Order Build Parts Table
-- To store the parts of a build that customer ordered at the time of order
CREATE TABLE order_product_build_parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_product_build_id UUID NOT NULL REFERENCES order_product_builds(id) ON DELETE CASCADE,
    part_variant_id UUID REFERENCES part_variants(id) ON DELETE SET NULL,
    part_variant_name VARCHAR(255) NOT NULL, -- Copy at time of order
    part_variant_sku VARCHAR(50), -- Copy at time of order
    price DECIMAL(10,2) NOT NULL, -- Price at time of order
    variant_options JSONB, -- Stores option details like color, size, etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX fk_order_product_build_parts_order_product_build_id ON order_product_build_parts(order_product_build_id);
CREATE INDEX fk_order_product_build_parts_part_variant_id ON order_product_build_parts(part_variant_id);

-- Order Price Adjustments Table
-- To store price adjustments applied to the build at the time of order
CREATE TABLE order_price_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_product_build_id UUID NOT NULL REFERENCES order_product_builds(id) ON DELETE CASCADE,
    price_adjustment_id UUID REFERENCES price_adjustments(id) ON DELETE SET NULL,
    price_adjustment_name VARCHAR(255) NOT NULL, -- Copy at time of order
    price_adjustment_description TEXT, -- Copy at time of order
    adjustment_amount DECIMAL(10,2) NOT NULL, -- Copy at time of order
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX fk_order_price_adjustments_order_product_build_id ON order_price_adjustments(order_product_build_id);
CREATE INDEX fk_order_price_adjustments_price_adjustment_id ON order_price_adjustments(price_adjustment_id);