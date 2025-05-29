#!/usr/bin/env python3
"""
Script to fix ProductEntity instances in test files to use the helper function
"""

import re

def fix_product_entity_instances(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Pattern to match ProductEntity constructor calls
    pattern = r'ProductEntity\(\s*id:\s*[\'"]([^\'"]*)[\'"],\s*name:\s*[\'"]([^\'"]*)[\'"],\s*price:\s*([^,\s]+),\s*imageUrl:\s*[\'"][^\'"]*[\'"],?\s*\)'
    
    def replace_match(match):
        id_val = match.group(1)
        name_val = match.group(2)
        price_val = match.group(3)
        return f"createTestProduct(id: '{id_val}', name: '{name_val}', price: {price_val})"
    
    # Replace all matches
    new_content = re.sub(pattern, replace_match, content)
    
    with open(file_path, 'w') as f:
        f.write(new_content)
    
    print(f"Fixed ProductEntity instances in {file_path}")

if __name__ == "__main__":
    fix_product_entity_instances("test/calculation/price_calculator_test.dart")
    print("Done!")
