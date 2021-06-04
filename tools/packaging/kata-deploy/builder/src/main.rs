use anyhow::{Context, Result};

mod builder;

fn main() -> Result<()> {
    let app_config = cmd::parse_args()?;

    match app_config.subcmd {
        cmd::SubCommand::Build(c) => {
            let mut b = builder::Builder::new();

            if let Some(t) = c.tar_output {
                b = b.tar_output(t)
            };

            b.build_asset(c.asset.as_str())
                .context("Failed to build asset")?
        }
    }

    Ok(())
}
