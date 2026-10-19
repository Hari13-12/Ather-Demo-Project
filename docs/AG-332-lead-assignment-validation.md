# AG-332 Lead assignment validation

Run these scenarios in an environment where the metadata has been deployed.

1. In Setup, open Lead Assignment Rules. Confirm `Standard` is the only active Lead assignment rule and that its existing country-based entries are present alongside the `Web` and `Partner Referral` entries.
2. Create a Lead with `LastName`, `Company`, and `LeadSource` set to `Web`. Select **Assign using active assignment rule** when saving. Confirm its owner is **Inbound Sales Queue**.
3. Create a Lead with `LeadSource` set to `Partner Referral` and assignment-rule processing enabled. Confirm its owner is **Partner Sales Queue**.
4. Create Leads with another source and with no source, each with assignment-rule processing enabled. Confirm the existing country-based default ownership remains in effect; the new source entries must not alter this fallback behavior.
5. Confirm **Inbound Sales Queue** contains the **Eastern Sales Team** role and **Partner Sales Queue** contains the **Channel Sales Team** role. Sign in as an active user in each role with Lead read, edit, and transfer access, then confirm that the user can open, accept, edit, and reassign a Lead owned by the corresponding queue.
6. Create Web, Partner Referral, Trade Show, and another-source Leads and confirm `Lead_Set_Priority_From_Lead_Source` remains active and assigns its existing High or Normal priority independently of the Lead owner.
7. Create Leads for `Web`, `Partner Referral`, and another source without selecting assignment-rule processing on an update. Confirm ownership is not automatically reassigned; assignment rules run on eligible create/import processing or when explicitly invoked.

Trade Show has no active LeadSource assignment entry or designated routing destination, so it remains on the existing default path.
