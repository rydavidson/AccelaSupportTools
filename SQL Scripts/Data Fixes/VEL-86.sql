/*
VEL-86.sql

Fixes the cause of VEL-86 by populating INSP_SEQ_NBR values in G6ACTION for entries where that is null
Compares the inspection type code between the transactional inspection (G6ACTION) and the reference inspection (RINSPTYP) and obtains the INSP_SEQ_NBR for the given inspection type.
Does not address inspection types that aren't present in RINSPTYP
Does not address inspection types where the inspection group code doesn't match RINSPTYP.INSP_CODE

TODO: Compare performance if I store the distinct inspection types types in a temp table and reference them in the loop versus using the lookup array. I think it'll be worse.
TODO: Check type + group combo when keeping track of already updated entries. Not needed for LEONCO but would be good to further limit updates for future runs.
TODO: Try to get the run time down. Takes ~ 20 seconds on my test server. Maybe figure out how to get this into a bulk update.
 */
declare
  cursor irows is
  -- Get the reference and transactional inspection types and groups for entries in G6ACTION that lack an INSP_SEQ_NBR
  select R.INSP_SEQ_NBR, G.G6_ACT_TYP, R.INSP_TYPE, G.INSP_GROUP
  from G6ACTION G, RINSPTYP R
  where R.INSP_TYPE = G.G6_ACT_TYP and R.SERV_PROV_CODE = 'LEONCO' and G.SERV_PROV_CODE = 'LEONCO' and G.INSP_SEQ_NBR is null and R.INSP_SEQ_NBR is not null;
  -- Lookup structure to track duplicated inspection type codes since I couldn't filter those out in the cursor itself
  type lookup is table of varchar2(255) index by varchar2(255);
  insp_code_lookup lookup;
  -- SERV_PROV_CODE
  spc varchar2(15);
  -- G6ACTION.G6_ACT_TYP - Inspection Type
  itype varchar2(255);
  -- G6ACTION.INSP_GROUP - Inspection Group
  igroup varchar2(12);

begin
  -- Set the SERV_PROV_CODE to update for
  spc := 'LEONCO';
  for irow in irows
  loop
      begin
      -- Pull the current inspection type and inspection group
      itype := irow.G6_ACT_TYP;
      igroup := irow.INSP_GROUP;
      -- Check if I've already tried running an update for this inspection type and skip this iteration if so
        if(insp_code_lookup.exists(itype)) then
          --dbms_output.put_line('Skipped existing INSP_TYPE: '||itype);
          continue;
        else
          -- Store the inspection type so later attempts skip over it
          insp_code_lookup(itype) := itype;
          --dbms_output.put_line('Stored INSP_TYPE: '||itype);
          -- Run the update
          UPDATE G6ACTION G SET G.INSP_SEQ_NBR =
            (SELECT R.INSP_SEQ_NBR from RINSPTYP R where R.SERV_PROV_CODE = spc and R.INSP_TYPE = itype and R.INSP_CODE = igroup)
          where G.INSP_SEQ_NBR is null and G.INSP_GROUP = igroup and G.G6_ACT_TYP = itype and G.SERV_PROV_CODE = spc;
        end if;
    end;
  end loop;
end;