# SplitMySub Manual Testing Scenarios

A comprehensive guide for manually testing SplitMySub functionality. This document provides step-by-step testing scenarios to ensure all features work correctly before deployment.

## 🎯 Testing Overview

This document covers manual testing scenarios for all major user flows and edge cases in SplitMySub. Each scenario includes:
- **Prerequisites**: What needs to be set up before testing
- **Test Steps**: Detailed step-by-step instructions
- **Expected Results**: What should happen at each step
- **Edge Cases**: Alternative scenarios and error conditions

---

## 🔐 Authentication & User Management

### **Scenario 1: New User Registration**

**Prerequisites:**
- Clean browser session (no existing cookies)
- Valid email address for testing

**Test Steps:**
1. Navigate to the application homepage
2. Click "Sign Up" or "Get Started"
3. Enter email address: `test@example.com`
4. Enter first name: `John`
5. Enter last name: `Doe`
6. Click "Create Account"
7. Check email inbox for magic link
8. Click the magic link in the email
9. Verify redirect to dashboard

**Expected Results:**
- ✅ Registration form accepts valid input
- ✅ Success message appears: "Magic link sent to your email"
- ✅ Email received within 30 seconds
- ✅ Magic link redirects to dashboard
- ✅ User is automatically signed in
- ✅ Welcome message displayed

**Edge Cases to Test:**
- Invalid email format (`invalid-email`)
- Empty required fields
- Duplicate email registration
- Expired magic link (wait 30+ minutes)
- Already used magic link

### **Scenario 2: Existing User Login**

**Prerequisites:**
- Existing user account

**Test Steps:**
1. Navigate to login page
2. Enter existing email address
3. Click "Send Magic Link"
4. Check email for magic link
5. Click magic link
6. Verify successful login

**Expected Results:**
- ✅ Magic link sent to existing user
- ✅ Successful login and redirect to dashboard
- ✅ User session persists across page refreshes

**Edge Cases to Test:**
- Non-existent email address
- Multiple magic link requests
- Magic link used after logout

### **Scenario 3: User Logout**

**Prerequisites:**
- Logged in user

**Test Steps:**
1. Click user menu/profile dropdown
2. Click "Logout" or "Sign Out"
3. Verify redirect to homepage
4. Try to access protected page directly

**Expected Results:**
- ✅ User successfully logged out
- ✅ Redirect to homepage or login page
- ✅ Protected pages redirect to login

---

## 📊 Project Management

### **Scenario 4: Create New Project**

**Prerequisites:**
- Logged in user

**Test Steps:**
1. Navigate to dashboard
2. Click "Create Project" or "New Project"
3. Fill out project form:
   - **Name**: "Netflix Family Plan"
   - **Description**: "Monthly Netflix subscription sharing"
   - **Cost**: "15.99"
   - **Currency**: "USD"
   - **Billing Cycle**: "Monthly"
   - **Renewal Date**: Select date 1 month from now
   - **Reminder Days**: "3"
4. Click "Create Project"
5. Verify project creation success

**Expected Results:**
- ✅ Form accepts all valid inputs
- ✅ Project created successfully
- ✅ Redirect to project detail page
- ✅ Project appears in user's project list
- ✅ Correct cost calculation shown
- ✅ Unique project slug generated

**Edge Cases to Test:**
- Empty required fields
- Invalid cost amounts (negative, text)
- Invalid date selection (past date)
- Very long project names/descriptions
- Special characters in project name
- Different currencies (EUR, GBP, JPY)

### **Scenario 5: Edit Existing Project**

**Prerequisites:**
- Logged in user who owns a project

**Test Steps:**
1. Navigate to project detail page
2. Click "Edit Project" or edit icon
3. Modify project details:
   - Change cost from "15.99" to "19.99"
   - Update description
   - Change reminder days to "5"
4. Click "Save Changes"
5. Verify updates are reflected

**Expected Results:**
- ✅ Edit form pre-populated with current values
- ✅ Changes saved successfully
- ✅ Updated values displayed on project page
- ✅ Cost per member recalculated if needed

**Edge Cases to Test:**
- Cancel editing without saving
- Invalid data during edit
- Editing project with existing payments
- Concurrent edits by multiple users

### **Scenario 6: Delete Project**

**Prerequisites:**
- Logged in user who owns a project with no payments

**Test Steps:**
1. Navigate to project detail page
2. Click "Delete Project" or delete icon
3. Confirm deletion in modal/confirmation dialog
4. Verify project is deleted

**Expected Results:**
- ✅ Confirmation dialog appears
- ✅ Project deleted after confirmation
- ✅ Redirect to dashboard or projects list
- ✅ Project no longer appears in user's projects

**Edge Cases to Test:**
- Cancel deletion
- Delete project with pending payments
- Delete project with confirmed payments
- Delete project with active members

---

## 👥 Member Invitation System

### **Scenario 7: Invite New Member**

**Prerequisites:**
- Logged in project owner
- Existing project

**Test Steps:**
1. Navigate to project detail page
2. Click "Invite Members" or "Add Member"
3. Enter email address: `newmember@example.com`
4. Select role (if applicable): "Member"
5. Click "Send Invitation"
6. Verify invitation sent confirmation
7. Check that invitation appears in project member list

**Expected Results:**
- ✅ Invitation form accepts valid email
- ✅ Success message: "Invitation sent successfully"
- ✅ Email sent to invitee
- ✅ Invitation appears in project member list as "Pending"
- ✅ Cost per member updates to reflect new potential member

**Edge Cases to Test:**
- Invalid email format
- Duplicate invitation to same email
- Invite existing project member
- Invite project owner
- Multiple invitations to different emails

### **Scenario 8: Accept Invitation (New User)**

**Prerequisites:**
- Valid invitation email received

**Test Steps:**
1. Open invitation email
2. Click "Accept Invitation" link
3. Fill out new user form:
   - **First Name**: "Jane"
   - **Last Name**: "Smith"
4. Click "Accept & Join Project"
5. Verify account creation and project membership

**Expected Results:**
- ✅ Invitation page loads with project details
- ✅ New user account created
- ✅ User automatically added to project
- ✅ Redirect to project page
- ✅ User can see project details and payment information
- ✅ Cost per member recalculated

**Edge Cases to Test:**
- Expired invitation link
- Already used invitation link
- Invalid invitation token
- Invitation for deleted project

### **Scenario 9: Accept Invitation (Existing User)**

**Prerequisites:**
- Existing user account
- Valid invitation email received

**Test Steps:**
1. Open invitation email
2. Click "Accept Invitation" link
3. If not logged in, complete login process
4. Confirm joining the project
5. Verify project membership

**Expected Results:**
- ✅ Existing user recognized
- ✅ Simple confirmation to join project
- ✅ User added to project member list
- ✅ Access to project details and payments

### **Scenario 10: Decline or Remove Member**

**Prerequisites:**
- Project with invited or active members

**Test Steps:**
1. As project owner, navigate to project members
2. Click "Remove" next to a member
3. Confirm removal
4. Verify member is removed and cost recalculated

**Expected Results:**
- ✅ Member removed from project
- ✅ Cost per member recalculated
- ✅ Removed member loses access to project
- ✅ Notification sent to removed member

---

## 💰 Payment Management

### **Scenario 11: Submit Payment (Member)**

**Prerequisites:**
- Logged in project member
- Active billing cycle with amount due

**Test Steps:**
1. Navigate to project page
2. Click "Make Payment" or "Pay Now"
3. Enter payment details:
   - **Amount**: "5.33" (or calculated amount)
   - **Transaction ID**: "TXN123456789"
   - **Payment Method**: "Bank Transfer"
   - **Notes**: "Paid via online banking"
4. Upload payment evidence (receipt/screenshot)
5. Click "Submit Payment"
6. Verify payment submission

**Expected Results:**
- ✅ Payment form accepts all inputs
- ✅ File upload works correctly
- ✅ Payment submitted with "Pending" status
- ✅ Payment appears in member's payment history
- ✅ Project owner receives notification
- ✅ Billing cycle shows partial payment

**Edge Cases to Test:**
- Submit payment without evidence
- Upload invalid file types
- Submit incorrect payment amount
- Submit payment twice for same billing cycle
- Very large file uploads
- Submit payment after due date

### **Scenario 12: Confirm Payment (Project Owner)**

**Prerequisites:**
- Logged in project owner
- Pending payment submission from member

**Test Steps:**
1. Navigate to project page
2. Click "Payment Confirmations" or notification
3. Review payment details:
   - Member name and amount
   - Transaction ID and notes
   - Payment evidence file
4. Download and verify evidence
5. Add confirmation notes: "Verified against bank statement"
6. Click "Confirm Payment"
7. Verify payment confirmation

**Expected Results:**
- ✅ Payment details clearly displayed
- ✅ Evidence file downloads correctly
- ✅ Confirmation notes saved
- ✅ Payment status changes to "Confirmed"
- ✅ Member receives confirmation notification
- ✅ Billing cycle payment status updates

**Edge Cases to Test:**
- Reject payment instead of confirming
- Confirm payment with missing evidence
- Confirm payment with incorrect amount
- Multiple payments pending confirmation

### **Scenario 13: Reject Payment (Project Owner)**

**Prerequisites:**
- Logged in project owner
- Pending payment submission from member

**Test Steps:**
1. Navigate to payment confirmation page
2. Review payment details
3. Add rejection notes: "Amount doesn't match expected payment"
4. Click "Reject Payment"
5. Verify payment rejection

**Expected Results:**
- ✅ Payment status changes to "Rejected"
- ✅ Rejection notes saved
- ✅ Member receives rejection notification
- ✅ Member can resubmit corrected payment
- ✅ Billing cycle remains unpaid

### **Scenario 14: Payment History and Tracking**

**Prerequisites:**
- User with payment history (multiple payments)

**Test Steps:**
1. Navigate to user dashboard or profile
2. Click "Payment History"
3. Review payment list:
   - Filter by project
   - Filter by status (pending, confirmed, rejected)
   - Sort by date
4. Click on individual payment for details
5. Verify payment tracking information

**Expected Results:**
- ✅ All payments displayed correctly
- ✅ Filtering works properly
- ✅ Sorting functions correctly
- ✅ Payment details accessible
- ✅ Status indicators clear and accurate

---

## 📅 Billing Cycle Management

### **Scenario 15: Automatic Billing Cycle Creation**

**Prerequisites:**
- Project with renewal date approaching

**Test Steps:**
1. Create project with renewal date tomorrow
2. Wait for or trigger billing cycle creation
3. Verify new billing cycle appears
4. Check billing cycle details:
   - Correct total amount
   - Proper due date
   - All members included
   - Correct amount per member

**Expected Results:**
- ✅ Billing cycle created automatically
- ✅ Correct calculations for total and per-member amounts
- ✅ All active members included
- ✅ Proper due date set
- ✅ Members receive payment reminders

**Edge Cases to Test:**
- Project with no members
- Project with pending member invitations
- Project with recently removed members
- Multiple projects with same renewal date

### **Scenario 16: Payment Reminder System**

**Prerequisites:**
- Billing cycle approaching due date
- Members with unpaid amounts

**Test Steps:**
1. Set up project with reminder days = 3
2. Create billing cycle due in 3 days
3. Verify reminder emails sent
4. Check reminder content and timing
5. Test multiple reminder scenarios

**Expected Results:**
- ✅ Reminders sent at correct intervals
- ✅ Email content includes payment details
- ✅ Links to payment submission work
- ✅ No reminders sent to members who already paid
- ✅ Project owner receives payment status updates

**Edge Cases to Test:**
- Reminders for overdue payments
- Multiple unpaid billing cycles
- Reminders when payment submitted but not confirmed
- Disable/enable reminder preferences

### **Scenario 17: Billing Cycle Completion**

**Prerequisites:**
- Billing cycle with all payments confirmed

**Test Steps:**
1. Confirm all member payments for a billing cycle
2. Verify billing cycle marked as "Paid"
3. Check that next billing cycle is created
4. Verify completion notifications sent

**Expected Results:**
- ✅ Billing cycle status changes to "Paid"
- ✅ Next billing cycle created automatically
- ✅ Completion notifications sent to all members
- ✅ Payment history updated correctly

---

## 🔍 Edge Cases and Error Scenarios

### **Scenario 18: Network and Connectivity Issues**

**Test Steps:**
1. Start form submission
2. Disconnect internet during submission
3. Reconnect and retry
4. Test partial form completion with connection issues

**Expected Results:**
- ✅ Appropriate error messages displayed
- ✅ Form data preserved where possible
- ✅ Clear instructions for retry
- ✅ No data corruption

### **Scenario 19: File Upload Edge Cases**

**Test Steps:**
1. Upload very large files (>10MB)
2. Upload files with special characters in names
3. Upload unsupported file types
4. Upload corrupted files
5. Upload files with no extension

**Expected Results:**
- ✅ File size limits enforced
- ✅ File type validation works
- ✅ Clear error messages for invalid files
- ✅ Proper handling of edge cases

### **Scenario 20: Currency and Decimal Handling**

**Test Steps:**
1. Create projects with different currencies:
   - USD: $15.99
   - EUR: €12.50
   - GBP: £9.99
   - JPY: ¥1500 (no decimals)
2. Test cost splitting with odd amounts
3. Verify currency formatting throughout app

**Expected Results:**
- ✅ All currencies display correctly
- ✅ Proper decimal handling for each currency
- ✅ Rounding handled appropriately
- ✅ Consistent currency display

### **Scenario 21: Concurrent User Actions**

**Test Steps:**
1. Have multiple users perform actions simultaneously:
   - Two users submitting payments
   - Owner confirming payment while member submits another
   - Multiple invitation acceptances
2. Verify data integrity

**Expected Results:**
- ✅ No data corruption
- ✅ Proper conflict resolution
- ✅ Appropriate error handling
- ✅ Consistent state across users

---

## 📱 Mobile and Responsive Testing

### **Scenario 22: Mobile Device Testing**

**Test Steps:**
1. Test on various mobile devices:
   - iPhone (Safari)
   - Android (Chrome)
   - iPad (Safari)
2. Test key user flows on mobile:
   - Registration and login
   - Project creation
   - Payment submission
   - File upload

**Expected Results:**
- ✅ All pages responsive and usable
- ✅ Touch interactions work properly
- ✅ Forms easy to complete on mobile
- ✅ File uploads work on mobile devices
- ✅ Navigation intuitive on small screens

### **Scenario 23: Cross-Browser Testing**

**Test Steps:**
1. Test on multiple browsers:
   - Chrome (latest)
   - Firefox (latest)
   - Safari (latest)
   - Edge (latest)
2. Test critical user flows in each browser

**Expected Results:**
- ✅ Consistent functionality across browsers
- ✅ Proper styling and layout
- ✅ JavaScript features work correctly
- ✅ File uploads compatible

---

## 🔒 Security Testing

### **Scenario 24: Authentication Security**

**Test Steps:**
1. Test magic link security:
   - Try using expired links
   - Try using links multiple times
   - Try accessing with invalid tokens
2. Test session management:
   - Session timeout
   - Logout functionality
   - Session persistence

**Expected Results:**
- ✅ Expired links rejected
- ✅ Used links cannot be reused
- ✅ Invalid tokens handled properly
- ✅ Sessions timeout appropriately
- ✅ Logout clears session completely

### **Scenario 25: Authorization Testing**

**Test Steps:**
1. Test access controls:
   - Try accessing other users' projects
   - Try confirming payments for projects you don't own
   - Try editing projects you're not owner of
2. Test URL manipulation:
   - Change project IDs in URLs
   - Try accessing admin areas

**Expected Results:**
- ✅ Proper authorization checks enforced
- ✅ Unauthorized access blocked
- ✅ Appropriate error messages shown
- ✅ No sensitive data exposed

### **Scenario 26: File Upload Security**

**Test Steps:**
1. Try uploading malicious files:
   - Executable files
   - Scripts
   - Files with malicious names
2. Test file access controls:
   - Try accessing other users' uploaded files
   - Try direct file URL access

**Expected Results:**
- ✅ Malicious files rejected
- ✅ File access properly controlled
- ✅ No direct file access without authorization
- ✅ File names sanitized

---

## 📊 Performance Testing

### **Scenario 27: Load Testing**

**Test Steps:**
1. Create projects with many members (10+)
2. Generate multiple billing cycles
3. Submit many payments
4. Test page load times with large datasets

**Expected Results:**
- ✅ Pages load within 3 seconds
- ✅ Forms remain responsive
- ✅ Database queries efficient
- ✅ No timeout errors

### **Scenario 28: File Upload Performance**

**Test Steps:**
1. Upload various file sizes:
   - Small files (<100KB)
   - Medium files (1-5MB)
   - Large files (5-10MB)
2. Test multiple concurrent uploads
3. Test upload progress indicators

**Expected Results:**
- ✅ Upload progress shown
- ✅ Large files upload successfully
- ✅ Concurrent uploads handled properly
- ✅ Appropriate timeout limits

---

## ✅ Testing Checklist

### **Pre-Release Testing Checklist**

**Authentication & Users:**
- [ ] New user registration works
- [ ] Magic link login works
- [ ] User logout works
- [ ] Session management proper
- [ ] Password-less authentication secure

**Project Management:**
- [ ] Create project works
- [ ] Edit project works
- [ ] Delete project works
- [ ] Project permissions enforced
- [ ] Cost calculations correct

**Member Management:**
- [ ] Send invitations works
- [ ] Accept invitations works (new users)
- [ ] Accept invitations works (existing users)
- [ ] Remove members works
- [ ] Member permissions enforced

**Payment Processing:**
- [ ] Submit payments works
- [ ] File upload works
- [ ] Confirm payments works
- [ ] Reject payments works
- [ ] Payment history accurate

**Billing Cycles:**
- [ ] Automatic creation works
- [ ] Payment reminders sent
- [ ] Billing completion works
- [ ] Next cycle creation works

**Security:**
- [ ] Authorization checks enforced
- [ ] File access controlled
- [ ] Magic links secure
- [ ] Session security proper

**Performance:**
- [ ] Page load times acceptable
- [ ] File uploads efficient
- [ ] Database queries optimized
- [ ] Mobile performance good

**Cross-Platform:**
- [ ] Works on Chrome
- [ ] Works on Firefox
- [ ] Works on Safari
- [ ] Works on mobile devices
- [ ] Responsive design proper

### **Post-Deployment Monitoring**

**Daily Checks:**
- [ ] Magic link emails delivering
- [ ] Payment reminders sending
- [ ] File uploads working
- [ ] Database backups running

**Weekly Checks:**
- [ ] Performance metrics review
- [ ] Error logs review
- [ ] User feedback review
- [ ] Security monitoring review

---

## 🐛 Common Issues and Troubleshooting

### **Magic Link Issues**
- **Problem**: Magic links not received
- **Check**: Email delivery logs, spam folders, email configuration
- **Solution**: Verify email service configuration, check DNS records

### **Payment Confirmation Issues**
- **Problem**: File uploads failing
- **Check**: File size limits, file type restrictions, storage space
- **Solution**: Adjust upload limits, clear storage space

### **Performance Issues**
- **Problem**: Slow page loads
- **Check**: Database query performance, file sizes, network connectivity
- **Solution**: Optimize queries, compress files, check hosting resources

### **Mobile Issues**
- **Problem**: Layout broken on mobile
- **Check**: CSS media queries, viewport settings, touch interactions
- **Solution**: Update responsive styles, test on actual devices

---

This manual testing guide ensures comprehensive coverage of all SplitMySub functionality. Use this checklist before each release to verify that all features work correctly and provide a smooth user experience. 