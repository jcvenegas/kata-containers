use clap::{AppSettings, Clap};
use thiserror::Error;

pub type Result<T> = std::result::Result<T, CliError>;

#[derive(Clap)]
#[clap(setting = AppSettings::ColoredHelp)]
pub struct Opts {
    #[clap(short, long, parse(from_occurrences))]
    verbose: i32,
    #[clap(short, long)]
    kata_repository: Option<String>,
    #[clap(subcommand)]
    pub subcmd: SubCommand,
}

impl Opts {
    pub fn get_log_level(self) -> LogLevel {
        match self.verbose {
            0 => LogLevel::None,
            1 => LogLevel::Error,
            2 => LogLevel::Warn,
            3 => LogLevel::Info,
            4 => LogLevel::Debug,
            _ => LogLevel::Trace,
        }
    }
    pub fn get_kata_repo_path(&self) -> String {
        match self.kata_repository.as_ref() {
            Some(s) => s.clone(),
            None => ".".to_string(),
        }
    }
}

#[derive(Clap)]
pub enum SubCommand {
    Build(BuildCmd),
}

/// Build kata-deploy image
#[derive(Clap)]
pub struct BuildCmd {
    pub asset: String,
    #[clap(short, long)]
    pub tar_output: Option<String>,
}

//impl BuildCmd{
//    fn exec(self) -> Result<()>{
//    }
//}
//
pub enum LogLevel {
    None,
    Error,
    Warn,
    Info,
    Debug,
    Trace,
}

#[derive(Debug, Error)]
pub enum CliError {
    #[error("failed to parse cli")]
    FailedToParse,
}

pub fn parse_args() -> Result<Opts> {
    let opts: Opts = Opts::parse();
    Ok(opts)
}
