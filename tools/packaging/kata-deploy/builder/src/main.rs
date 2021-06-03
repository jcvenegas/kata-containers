use anyhow::{bail, Context, Result};

struct Builder;

impl Builder {
    fn build_cloud_hypervisor() -> Result<()> {
        println!("Build cloud-hypervisor");
        Ok(())
    }

    fn build_firecracker() -> Result<()> {
        println!("Build firecracker");
        Ok(())
    }

    fn build_guest_rootfs() -> Result<()> {
        println!("Build guest-rootfs");
        Ok(())
    }

    fn build_kernel() -> Result<()> {
        println!("Build kernel");
        Ok(())
    }

    fn build_qemu() -> Result<()> {
        println!("Build qemu");
        Ok(())
    }

    fn build_shim_v2() -> Result<()> {
        println!("Build shim-v2");
        Ok(())
    }
}

fn build_asset(asset: &str) -> Result<()> {
    match asset {
        "cloud-hypervisor" => {
            Builder::build_cloud_hypervisor().context("Failed to build cloud-hypervisor")
        }
        "firecracker" => Builder::build_firecracker().context("Failed to build firecracker"),
        "guest-rootfs" => Builder::build_guest_rootfs().context("Failed to build guest-rootfs"),
        "kernel" => Builder::build_kernel().context("Failed to build kernel"),
        "qemu" => Builder::build_qemu().context("Failed to build qemu"),
        "shim-v2" => Builder::build_shim_v2().context("Failed to build shim-v2"),
        _ => bail!("Asset '{}' is not valid", asset),
    }
}

fn main() -> Result<()> {
    let app_config = cmd::parse_args()?;

    match app_config.subcmd {
        cmd::SubCommand::Build(b) => {
            build_asset(b.asset.as_str()).context("Failed to build asset")?
        }
    }

    Ok(())
}
