# The Aftermath of the 2026 Oil Shock: Some Alternative Macroeconomic Scenarios

**Jonas D. M. Fisher, Will Pennington, and Alessandro Villa**  
*Chicago Fed Letter*, No. 523, July 2026. Federal Reserve Bank of Chicago.  
DOI: [10.21033/cfl-2026-523](https://doi.org/10.21033/cfl-2026-523) · [Article](https://www.chicagofed.org/publications/chicago-fed-letter/2026/523)

This package contains the MATLAB code, Dynare model, and public EIA input for Figures 1–4. **Licensed Haver/Bloomberg observations and the CSVs derived from them are intentionally excluded pending confirmation of redistribution rights.** 

Open MATLAB with this directory as the **Current Folder**. The scripts use relative paths. 

## Requirements and inputs

- MATLAB; [Dynare 7.0](https://www.dynare.org/) is required for `Fig2.m`–`Fig4.m`.
- `fig1.m` requires authorized access to the Haver Analytics `cbd.data` interface, a personal [FRED API key](https://fred.stlouisfed.org/docs/api/api_key.html), and an internet connection. It uses the included `data_raw/petroleum_consumption_ann.xls`, sourced from the [U.S. Energy Information Administration (EIA)](https://www.eia.gov/dnav/pet/hist/LeafHandler.ashx?n=PET&s=MTTUPUS2&f=A).
- `commodity_prices.m` requires authorized commodity and oil-futures data in `data_raw/commodityprices.csv` plus the corresponding series-information file `data_raw/commodities_info.xlsx`. These Bloomberg-sourced files are **not** included.
- `Fig2.m` and `Fig3.m` require `data_created/wtifutures_exp_March.csv`, produced by `commodity_prices.m`. `Fig4.m` also requires `data_created/wtichanges_seventies.csv`, produced by `fig1.m`. 

## Platform setup

In `Fig2.m`, `Fig3.m`, and `Fig4.m`, set `AleDirectory=1` on an Apple Silicon Mac using Dynare at `/Applications/Dynare/7.0-arm64/matlab`, or leave it at `0` for Dynare at `C:\dynare\7.0\matlab` on Windows. If Dynare is installed elsewhere, edit the relevant `addpath` in **each** model script.

In `fig1.m`, change the legacy Windows Haver `addpath` to the location of your authorized `cbd` installation. `commodity_prices.m` contains the same legacy `addpath`, but does not call Haver.

## Run the figures

1. Place the authorized Bloomberg files at the exact paths listed above and run `commodity_prices.m`. It writes `data_created/wtifutures_exp_March.csv` and the auxiliary plot `figures_png/wti_expectations.png`.
2. Configure Haver access, insert **your own** FRED key between the quotes in the `api_key = '';` line of `fig1.m`, and run `fig1.m`. It writes `data_created/wtichanges_seventies.csv` and `figures_png/fig1.png`. Remove your key before sharing any edited script.
3. Configure Dynare and run `Fig2.m`, `Fig3.m`, and `Fig4.m` to generate `figures_png/fig2.png`, `figures_png/fig3.png`, and `figures_png/fig4.png`. Leave `casename = "Baseline"` and `printfigs = 1` for the article figures. The Dynare model is `oil_nonlinear_kstickyEPF_export3_sf.mod`.

The `figures_png/` directory is supplied empty. Dynare generates model code, results, and a log during execution; these generated files are not part of the distributed package. `fig1.m` requests Haver observations through the current date, and external data can be revised, so later full reruns may differ from the original publication.

## Data provenance

The included `petroleum_consumption_ann.xls` is an EIA spreadsheet for the annual U.S. product-supplied series. Source: U.S. Energy Information Administration, [U.S. Product Supplied of Crude Oil and Petroleum Products](https://www.eia.gov/dnav/pet/hist/LeafHandler.ashx?n=PET&s=MTTUPUS2&f=A), downloaded in 2026. The EIA [permits redistribution of its website data with acknowledgment](https://www.eia.gov/about/copyrights_reuse.php).
