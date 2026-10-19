# AG-332 Lead assignment validation

Run these scenarios in an environment where the metadata has been deployed.

1. Create a Lead with `LastName`, `Company`, and `LeadSource` set to `Web`. Select **Assign using active assignment rule** when saving. Confirm its owner is **Inbound Sales Queue** and the existing priority automation independently sets the expected priority.
2. Create a Lead with `LeadSource` set to `Partner Referral` and assignment-rule processing enabled. Confirm its owner is **Partner Sales Queue** and its priority remains governed by the existing priority Flow.
3. Create Leads with another source and with no source, each with assignment-rule processing enabled. Confirm the existing country-based default ownership remains in effect.
4. Open both queues and confirm that All Internal Users is listed as a member. Sign in as a user with Lead read, edit, and transfer access to confirm that queued Leads can be worked and reassigned.
5. Create Leads for `Web`, `Partner Referral`, and another source without selecting assignment-rule processing on an update. Confirm ownership is not automatically reassigned; assignment rules run on eligible create/import processing or when explicitly invoked.

Trade Show has no active LeadSource value or designated destination in the inspected org, so it intentionally remains on the existing default path.
