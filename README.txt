Data analysis is broken up into several components.

This README gives a brief overview of files in `code` file:

<00_initial_data_helper.py>
Python script; unzips files of interest from the IFLS data.
NOTE: This component isn't relevant to data analysis, and is hard to replicate as it is highly dependent on setting up an identical directory structure.

<01_get_drought_index.do>
Stata do-file; it's a two part script.
Part 1: prepares data to be fed to <02_geocoder.py>.
Part 2: constructs the drought indices.

<02_geocoder.py>
Python script; takes latitude-longitude pairs from all stations in the drought data and looks up the province using a geocoding API service.

<03_BPS_crosswalk_helper.py>
Python script; creates a crosswalk of province name to BPS province code based on a text file that was copied and pasted.
NOTE: BPS is Indonesia's government statistical agency.

<04_analysis.do>
Stata do-file; puts together all of the data from various sources, and constructs the relevant resources for tables (summary stats + regressions + wald tests).

<05_output_helper.py>
Python script; formats the output of <04_analysis.do> so to avoid tedious work.