#!/usr/bin/env python3
"""
Script to update AdminLayout calls to include selectedRoute and title parameters
"""

import os
import re

# Define the routes mapping for different admin screens
routes_mapping = {
    'admin_products': '/admin/products',
    'admin_customers': '/admin/customers', 
    'admin_orders': '/admin/orders',
    'admin_categories': '/admin/categories',
    'admin_brands': '/admin/brands',
    'admin_attributes': '/admin/attributes',
    'admin_warehouses': '/admin/warehouses',
    'admin_suppliers': '/admin/suppliers',
    'admin_stock_checker': '/admin/stock-checkers',
    'admin_stock_ins': '/admin/stock-ins',
    'admin_stock_outs': '/admin/stock-outs',
    'admin_inventory_reports': '/admin/inventory-reports',
    'admin_banners': '/admin/banners',
}

# Define titles mapping
titles_mapping = {
    'admin_products': 'Products',
    'admin_customers': 'Customers',
    'admin_orders': 'Orders', 
    'admin_categories': 'Categories',
    'admin_brands': 'Brands',
    'admin_attributes': 'Attributes',
    'admin_warehouses': 'Warehouses',
    'admin_suppliers': 'Suppliers',
    'admin_stock_checker': 'Stock Checkers',
    'admin_stock_ins': 'Stock-In',
    'admin_stock_outs': 'Stock-Out',
    'admin_inventory_reports': 'Inventory Reports',
    'admin_banners': 'Banners',
}

def update_admin_layout_file(file_path):
    """Update AdminLayout call in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check if this file has AdminLayout
        if 'AdminLayout(' not in content:
            return False
            
        # Get the folder name to determine the route
        folder_name = os.path.basename(os.path.dirname(file_path))
        
        # Find the matching route
        route = None
        title = None
        
        for key, value in routes_mapping.items():
            if key in folder_name:
                route = value
                title = titles_mapping.get(key, key.replace('admin_', '').replace('_', ' ').title())
                break
        
        if not route:
            print(f"Warning: No route mapping found for {folder_name} in {file_path}")
            return False
            
        # Pattern to match AdminLayout calls
        pattern = r'(return\s+AdminLayout\(\s*)child:\s*Padding\('
        replacement = rf'\1selectedRoute: \'{route}\',\n      title: \'{title}\',\n      child: Padding('
        
        # Update the content
        updated_content = re.sub(pattern, replacement, content)
        
        if updated_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(updated_content)
            print(f"Updated: {file_path}")
            return True
        else:
            print(f"No changes needed: {file_path}")
            return False
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Main function to process all admin files"""
    admin_dir = "lib/views/admin"
    
    if not os.path.exists(admin_dir):
        print(f"Directory {admin_dir} does not exist")
        return
    
    updated_count = 0
    total_count = 0
    
    # Walk through all directories and files
    for root, dirs, files in os.walk(admin_dir):
        for file in files:
            if file == "index.dart":
                file_path = os.path.join(root, file)
                total_count += 1
                if update_admin_layout_file(file_path):
                    updated_count += 1
    
    print(f"\nSummary: Updated {updated_count}/{total_count} files")

if __name__ == "__main__":
    main()