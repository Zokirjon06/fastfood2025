# UI Testing Checklist - Interactive Elements

## 📱 **Mobile View Testing (< 600px)**

### **Product Selection & Management**
- [ ] **Product Card Tap**: Toggles selection correctly (add/remove)
- [ ] **Visual Feedback**: Selected products show amber border + checkmark
- [ ] **Remove Button**: Red remove button appears on selected products
- [ ] **Selection Counter**: "Buyurtma: X ta" updates correctly
- [ ] **Haptic Feedback**: Light vibration on product selection
- [ ] **Long Press**: Opens edit/delete page correctly
- [ ] **State Persistence**: Selection persists across page navigation

### **Pagination Controls**
- [ ] **Previous Button**: Navigates to previous page (disabled on first page)
- [ ] **Next Button**: Navigates to next page (disabled on last page)
- [ ] **Page Indicators**: Clickable page numbers (max 5 visible)
- [ ] **Smart Pagination**: Shows correct range for many pages
- [ ] **Page Header**: Shows "Mahsulotlar: X-Y / Total" and "Sahifa X/Y"
- [ ] **Haptic Feedback**: Light vibration on page navigation
- [ ] **Animation**: Smooth page transitions (300ms)

### **Search Functionality**
- [ ] **Search Button**: Opens search mode correctly
- [ ] **Search Input**: Filters products in real-time
- [ ] **Back Button**: Exits search mode and returns to normal view
- [ ] **Clear Button**: Appears when text exists, clears search properly
- [ ] **Search Reset**: Resets pagination to page 1 after search
- [ ] **Auto Focus**: Search input gets focus when entering search mode

### **AppBar Controls**
- [ ] **Clear All Button**: Appears only when products are selected
- [ ] **Clear All Function**: Clears all selections with confirmation message
- [ ] **Add Product Button**: Opens add product modal
- [ ] **Back Button**: Navigates to splash page
- [ ] **Tooltips**: All buttons show helpful tooltips

---

## 🖥️ **Tablet/Desktop View Testing (≥ 600px)**

### **Continuous Scrolling**
- [ ] **Lazy Loading**: Loads more items at 80% scroll position
- [ ] **Loading Indicator**: Shows "Loading more products..." at bottom
- [ ] **End Indicator**: Shows "All products loaded" when complete
- [ ] **Memory Management**: Handles large lists without crashes
- [ ] **Scroll Performance**: Smooth scrolling without lag

### **Responsive Grid**
- [ ] **Tablet Grid**: 4 cards per row on tablet screens
- [ ] **Desktop Grid**: 5-8 cards per row (dynamic based on width)
- [ ] **Card Spacing**: Consistent spacing between cards
- [ ] **Card Sizing**: Appropriate card heights for screen size

### **Product Count Indicator**
- [ ] **Count Display**: Shows "Ko'rsatilgan: X / Total"
- [ ] **Scroll Hint**: Shows "Scroll down for more" when applicable
- [ ] **Updates**: Count updates correctly as more items load

---

## 🔄 **Tab Switching Testing**

### **Hall Tab**
- [ ] **Tab Selection**: Highlights correctly when selected
- [ ] **Product Display**: Shows all products correctly
- [ ] **FAB Behavior**: Shows send icon, navigates to AddDeskId
- [ ] **State Persistence**: Maintains selection across tab switches

### **Delivery Tab**
- [ ] **Tab Selection**: Highlights correctly when selected
- [ ] **Product Display**: Shows same products as Hall tab
- [ ] **FAB Behavior**: Shows delivery icon, creates order directly
- [ ] **Order Creation**: Successfully creates delivery orders

---

## 🎯 **Floating Action Button Testing**

### **Visibility**
- [ ] **Show Condition**: Appears only when products are selected
- [ ] **Hide Condition**: Disappears when no products selected
- [ ] **Position**: Centered at bottom with proper spacing

### **Functionality**
- [ ] **Hall Mode**: Navigates to AddDeskId page
- [ ] **Delivery Mode**: Creates delivery order directly
- [ ] **State Reset**: Clears selection after navigation
- [ ] **Error Handling**: Shows error messages for failed operations

---

## 🔍 **Search System Testing**

### **Search Entry/Exit**
- [ ] **Enter Search**: Search button opens search mode
- [ ] **Exit Search**: Back button returns to normal view
- [ ] **State Reset**: Clears search text and resets pagination
- [ ] **Focus Management**: Proper focus handling

### **Search Functionality**
- [ ] **Real-time Filter**: Products filter as user types
- [ ] **Empty Results**: Handles no results gracefully
- [ ] **Clear Search**: Clear button resets to all products
- [ ] **Performance**: No lag during typing

---

## 🎨 **Visual Feedback Testing**

### **Product Selection Indicators**
- [ ] **Border Color**: Amber border for selected products
- [ ] **Background Color**: Light amber background for selected
- [ ] **Checkmark**: Green checkmark overlay on selected products
- [ ] **Shadow Effect**: Enhanced shadow for selected products

### **Button States**
- [ ] **Enabled State**: Proper colors and interactions
- [ ] **Disabled State**: Grayed out when not applicable
- [ ] **Hover Effects**: Appropriate hover states (desktop)
- [ ] **Press Effects**: Visual feedback on button press

---

## 📳 **Haptic Feedback Testing**

### **Light Impact**
- [ ] **Product Selection**: Vibrates on tap
- [ ] **Page Navigation**: Vibrates on page change
- [ ] **Button Presses**: Vibrates on interactive elements

### **Medium Impact**
- [ ] **Clear All**: Stronger vibration for bulk actions
- [ ] **Important Actions**: Medium feedback for significant operations

---

## 🔄 **Device Rotation Testing**

### **State Persistence**
- [ ] **Selection State**: Selected products remain selected
- [ ] **Page State**: Current page position maintained
- [ ] **Search State**: Search mode and text preserved

### **Layout Adaptation**
- [ ] **Mobile to Tablet**: Switches from pagination to continuous scroll
- [ ] **Tablet to Mobile**: Switches from continuous scroll to pagination
- [ ] **Grid Adjustment**: Card count adjusts to new screen size

---

## 🚨 **Error Handling Testing**

### **Network Issues**
- [ ] **Loading Errors**: Shows appropriate error messages
- [ ] **Retry Mechanism**: Allows user to retry failed operations
- [ ] **Graceful Degradation**: App remains functional during errors

### **Memory Issues**
- [ ] **Large Lists**: Handles thousands of products without crashes
- [ ] **Memory Cleanup**: Properly cleans up unused resources
- [ ] **Performance**: Maintains smooth performance under load

---

## 🎯 **Edge Cases Testing**

### **Empty States**
- [ ] **No Products**: Shows "Ma'lumot yo'q" message
- [ ] **No Search Results**: Handles empty search results
- [ ] **Loading State**: Shows loading indicator appropriately

### **Boundary Conditions**
- [ ] **First Page**: Previous button disabled
- [ ] **Last Page**: Next button disabled
- [ ] **Single Page**: No pagination controls shown
- [ ] **Single Product**: Selection works with one item

---

## ✅ **Final Verification Checklist**

### **Core Functionality**
- [ ] All product selection operations work correctly
- [ ] All navigation controls function properly
- [ ] Search system operates smoothly
- [ ] Tab switching maintains state correctly
- [ ] Floating action button behaves appropriately

### **User Experience**
- [ ] Visual feedback is clear and consistent
- [ ] Haptic feedback enhances interactions
- [ ] Animations are smooth and purposeful
- [ ] Error messages are helpful and clear

### **Performance**
- [ ] App responds quickly to user interactions
- [ ] Memory usage remains reasonable
- [ ] Scrolling is smooth on all devices
- [ ] No crashes or freezes during testing

### **Compatibility**
- [ ] Works correctly on mobile devices
- [ ] Functions properly on tablets
- [ ] Operates smoothly on desktop
- [ ] Handles device rotation gracefully

---

## 📊 **Testing Sign-off**

**Tester**: ________________  
**Date**: ________________  
**Device(s) Tested**: ________________  
**Overall Status**: ⭕ PASS / ❌ FAIL  
**Notes**: ________________

---

**All items must be checked (✅) for complete verification of UI functionality.**
