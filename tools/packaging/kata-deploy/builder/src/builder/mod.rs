use anyhow::bail;
use anyhow::{Context, Result};
use std::process::Command;
use std::str;

pub struct Builder {
    tar_output: Option<String>,
}

impl Builder {
    pub fn new() -> Self {
        Self { tar_output: None }
    }

    pub fn tar_output(mut self, tar_output: String) -> Self {
        self.tar_output = Some(tar_output);
        self
    }

    pub fn build_asset(&self, asset: &str) -> Result<()> {
        self.exec_cmd("./setup.sh", asset)?;
        self.exec_cmd("./build.sh", asset)?;
        Ok(())
    }
    fn exec_cmd(&self, c: &str, asset: &str) -> Result<()> {
        let build_dir = format!("./scripts/build-scripts/{}", asset);
        let default_tar = format!("{}.tar.gz", asset);
        let env_tar_output = match self.tar_output.as_ref() {
            Some(s) => s.as_str(),
            None => default_tar.as_str(),
        };

        let output = Command::new("sh")
            .arg("-c")
            .env("TAR_OUTPUT", env_tar_output)
            .current_dir(&build_dir)
            .arg(c)
            .output()
            .context(format!("failed to exec setup {} {}", build_dir, asset))?;

        if !output.status.success() {
            bail!("Failed to exec {}: Exit code not zero", c)
        }
        println!("{} output: {}", asset, str::from_utf8(&output.stdout)?);
        Ok(())
    }
}
