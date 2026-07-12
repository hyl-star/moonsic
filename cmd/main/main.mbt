///|
/// Run the stable end-to-end composition demo and print an asset summary.
fn main {
  let request = @demo.default_composition_request()
  match @demo.composition_asset_pipeline_checked(request) {
    Ok(bundle) => println(@demo.composition_asset_bundle_to_json(bundle))
    Err(error) => abort("moonsic demo failed: " + error.to_string())
  }
}
