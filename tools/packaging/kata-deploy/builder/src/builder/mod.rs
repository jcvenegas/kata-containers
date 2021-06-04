use anyhow::bail;
use anyhow::{Context, Result};
use std::path::Path;
use std::process::Command;
use std::str;

pub struct Builder {
    tar_output: Option<String>,
    kata_repository: String,
}

impl Builder {
    pub fn new() -> Self {
        Self {
            tar_output: None,
            kata_repository: ".".to_string(),
        }
    }

    pub fn tar_output(mut self, tar_output: String) -> Self {
        self.tar_output = Some(tar_output);
        self
    }
    pub fn kata_repository(mut self, r: String) -> Self {
        self.kata_repository = r;
        self
    }

    pub fn build_asset(&self, asset: &str) -> Result<()> {
        self.exec_cmd("setup.sh", asset)?;
        self.exec_cmd("build.sh", asset)?;
        Ok(())
    }
    fn exec_cmd(&self, c: &str, asset: &str) -> Result<()> {
        let exec_path = Path::new(self.kata_repository.as_str())
            .join("tools/packaging/kata-deploy/builder/scripts/build-scripts")
            .join(asset)
            .join(c);
        let default_tar = format!("{}.tar.gz", asset);
        let env_tar_output = match self.tar_output.as_ref() {
            Some(s) => s.as_str(),
            None => default_tar.as_str(),
        };

        let output = Command::new("sh")
            .arg("-c")
            .env("TAR_OUTPUT", env_tar_output)
            .arg(&exec_path)
            .output()
            .context(format!("Failed to exec: {:?}", exec_path))?;

        if !output.status.success() {
            bail!("Failed to exec {:?}: Exit code not zero", exec_path)
        }
        println!("{} output: {}", asset, str::from_utf8(&output.stdout)?);
        Ok(())
    }
}
