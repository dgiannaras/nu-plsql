Create Or Replace View v_af_alumni_summary As
With

/* All Kellogg alumni households and annual fund giving behavior.
   Base table is nu_prs_trp_prospect so deceased entities are excluded. */

-- Calendar date range from current_calendar
cal As (
  Select curr_fy, yesterday
  From v_current_calendar
),

-- Housheholds
hh As (
  Select hh.id_number, hh.pref_mail_name, hh.degrees_concat, hh.program_group,
    hh.spouse_id_number, hh.spouse_pref_mail_name, hh.spouse_degrees_concat, hh.spouse_program_group,
    hh.household_id, hh.household_ksm_year, hh.household_masters_year, hh.household_program_group
  From table(ksm_pkg.tbl_entity_households_ksm) hh
  Where hh.household_ksm_year Is Not Null
),

-- Kellogg Annual Fund allocations as defined in ksm_pkg
ksm_af_allocs As (
  Select allocation_code
  From table(ksm_pkg.tbl_alloc_annual_fund_ksm)
),

-- First gift year
first_af As (
  Select Distinct household_id, min(fiscal_year) As first_af_gift_year
  From table(ksm_pkg.tbl_gift_credit_hh_ksm) gft
  Inner Join ksm_af_allocs On ksm_af_allocs.allocation_code = gft.allocation_code
  Where tx_gypm_ind <> 'P'
    And af_flag = 'Y'
    And recognition_credit > 0
  Group By household_id
)

Select Distinct
  -- Household fields
  hh.household_id, hh.pref_mail_name, hh.degrees_concat, hh.household_masters_year, hh.household_ksm_year,
  hh.program_group, hh.spouse_id_number, hh.spouse_pref_mail_name, hh.spouse_degrees_concat,
  hh.spouse_program_group, hh.household_program_group,
  -- Entity-based fields
  prs.record_status_code, prs.pref_city, prs.pref_zip, prs.pref_state, tms_states.short_desc As pref_state_desc,
  tms_country.short_desc As preferred_country, prs.business_title,
  trim(prs.employer_name1 || ' ' || prs.employer_name2) As employer_name,
  -- Giving fields
  af_summary.ksm_af_curr_fy, af_summary.ksm_af_prev_fy1, af_summary.ksm_af_prev_fy2, af_summary.ksm_af_prev_fy3,
  af_summary.ksm_af_prev_fy4, af_summary.ksm_af_prev_fy5, af_summary.ksm_af_prev_fy6, af_summary.ksm_af_prev_fy7,
  first_af.first_af_gift_year,
  cru_curr_fy, cru_prev_fy1, cru_prev_fy2, cru_curr_fy_ytd, cru_prev_fy1_ytd, cru_prev_fy2_ytd,
  -- Prospect fields
  prs.prospect_id, prs.prospect_manager, prs.team, prs.prospect_stage, prs.officer_rating, prs.evaluation_rating,
  -- Indicators
  af_summary.kac, af_summary.gab, af_summary.trustee, af_summary.klc_cfy, af_summary.klc_pfy1, af_summary.klc_pfy2,
  -- Calendar objects
  cal.curr_fy, cal.yesterday
From nu_prs_trp_prospect prs
Cross Join cal
Inner Join hh On hh.household_id = prs.id_number
Left Join v_af_donors_5fy_summary af_summary On af_summary.id_hh_src_dnr = hh.household_id
Left Join first_af On first_af.household_id = prs.id_number
Left Join tms_states On tms_states.state_code = prs.pref_state
Left Join tms_country On tms_country.country_code = prs.preferred_country
Where hh.household_id = hh.id_number
