module Cardano.CLI.Byron.Parsers
  ( ByronCommand(..)
  , parseByronCommands
  , parseHeavyDelThd
  , parseInstallerHash
  , parseMaxBlockSize
  , parseMaxHeaderSize
  , parseMaxTxSize
  , parseMaxProposalSize
  , parseMpcThd
  , parseScriptVersion
  , parseSlotDuration
  , parseSoftforkRuleParam
  , parseSystemTag
  , parseTxFeePolicy
  , parseUpdateProposalThd
  , parseUpdateProposalTTL
  , parseUnlockStakeEpoch
  , parseUpdateVoteThd
  ) where

import           Cardano.Prelude hiding (option)

import           Options.Applicative

import           Cardano.Chain.Common
                   (TxFeePolicy(..), TxSizeLinear(..), rationalToLovelacePortion)
import           Cardano.Crypto.Hashing (decodeHash)
import           Cardano.Chain.Slotting (EpochNumber(..), SlotNumber(..))
import           Cardano.Chain.Update (InstallerHash(..), SoftforkRule(..), SystemTag(..))

import           Cardano.CLI.Byron.UpdateProposal
import           Cardano.Common.Parsers
                   (command', parseConfigFile, parseDbPath, parseFilePath,
                    parseFraction, parseLovelace, parseSigningKeyFile)
import           Cardano.Config.Types

-- TODO: Other Byron commands to be put here in follow up PR.
data ByronCommand = UpdateProposal
                    DbFile
                    ConfigYamlFilePath
                    SigningKeyFile
                    FilePath
                    [ParametersToUpdate]
                    deriving Show

parseByronCommands :: Parser ByronCommand
parseByronCommands =  subparser $ mconcat
    [ commandGroup "Byron related commands"
    , metavar "Byron related commands"
    , command' "create-byron-update-proposal" "Create Byron era update proposal."
        $ parseAllParamsToUpdate
    ]

parseAllParamsToUpdate :: Parser ByronCommand
parseAllParamsToUpdate = do
  (\dbfile config sKey outputFp a b c d e f g h i j k l m n ->
      UpdateProposal dbfile config sKey outputFp $ catMaybes [a, b, c, d, e, f, g, h, i, j, k, l, m, n])
    <$> (DbFile <$> parseDbPath)
    <*> (ConfigYamlFilePath <$> parseConfigFile)
    <*> parseSigningKeyFile "signing-key" "Path to signing key."
    <*> parseFilePath "filepath" "Output filepath"
    <*> parseScriptVersion
    <*> parseSlotDuration
    <*> parseMaxBlockSize
    <*> parseMaxHeaderSize
    <*> parseMaxTxSize
    <*> parseMaxProposalSize
    <*> parseMpcThd
    <*> parseHeavyDelThd
    <*> parseUpdateVoteThd
    <*> parseUpdateProposalThd
    <*> parseUpdateProposalTTL
    <*> parseSoftforkRuleParam
    <*> parseTxFeePolicy
    <*> parseUnlockStakeEpoch

--------------------------------------------------------------------------------
-- CLI Parsers
--------------------------------------------------------------------------------

parseScriptVersion :: Parser (Maybe ParametersToUpdate)
parseScriptVersion = optional $
  ScriptVersion <$> option auto
                      ( long "script-version"
                      <> metavar "WORD16"
                      <> help "Proposed script version."
                      )

parseSlotDuration :: Parser (Maybe ParametersToUpdate)
parseSlotDuration = optional $
  SlotDuration <$> option auto
                     ( long "slot-duration"
                     <> metavar "NATURAL"
                     <> help "Proposed slot duration."
                     )

parseSystemTag :: Parser SystemTag
parseSystemTag =
  SystemTag <$> strOption
                  ( long "system-tag"
                  <> metavar "SYSTAG"
                  <> help "Identify which system (linux, win64, etc) the update proposal is for."
                  )

parseInstallerHash :: Parser InstallerHash
parseInstallerHash =
  InstallerHash <$> option (eitherReader (\str' -> first toS . decodeHash $ toS str'))
                      ( long "installer-hash"
                      <> metavar "HASH"
                      <> help "Software hash."
                      )

parseMaxBlockSize :: Parser (Maybe ParametersToUpdate)
parseMaxBlockSize = optional $
  MaxBlockSize <$> option auto
                     ( long "max-block-size"
                     <> metavar "NATURAL"
                     <> help "Proposed max block size."
                     )

parseMaxHeaderSize :: Parser (Maybe ParametersToUpdate)
parseMaxHeaderSize = optional $
  MaxHeaderSize <$> option auto
                      ( long "max-header-size"
                      <> metavar "NATURAL"
                      <> help "Proposed max block header size."
                      )

parseMaxTxSize :: Parser (Maybe ParametersToUpdate)
parseMaxTxSize = optional $
  MaxTxSize <$> option auto
                  ( long "max-tx-size"
                  <> metavar "NATURAL"
                  <> help "Proposed max transaction size."
                  )

parseMaxProposalSize :: Parser (Maybe ParametersToUpdate)
parseMaxProposalSize = optional $
  MaxProposalSize <$> option auto
                        ( long "max-proposal-size"
                        <> metavar "NATURAL"
                        <> help "Proposed max update proposal size."
                        )

parseMpcThd :: Parser (Maybe ParametersToUpdate)
parseMpcThd = optional $
  MpcThd . rationalToLovelacePortion
    <$> parseFraction "max-mpc-thd" "Proposed max mpc threshold."

parseHeavyDelThd :: Parser (Maybe ParametersToUpdate)
parseHeavyDelThd = optional $
  HeavyDelThd . rationalToLovelacePortion
    <$> parseFraction "heavy-del-thd" "Proposed heavy delegation threshold"

parseUpdateVoteThd :: Parser (Maybe ParametersToUpdate)
parseUpdateVoteThd = optional $
  UpdateVoteThd . rationalToLovelacePortion
    <$> parseFraction "update-vote-thd" "Propose update vote threshold."

parseUpdateProposalThd :: Parser (Maybe ParametersToUpdate)
parseUpdateProposalThd = optional $
  UpdateProposalThd . rationalToLovelacePortion
    <$> parseFraction "update-proposal-thd" "Propose update proposal threshold."

parseUpdateProposalTTL :: Parser (Maybe ParametersToUpdate)
parseUpdateProposalTTL = optional $
  UpdateProposalTTL . SlotNumber
    <$> option auto
          ( long "time-to-live"
          <> metavar "WORD64"
          <> help "Proposed time for an update proposal to live."
          )

parseSoftforkRuleParam :: Parser (Maybe ParametersToUpdate)
parseSoftforkRuleParam = optional $
  SoftforkRuleParam
    <$> (SoftforkRule
           <$> (rationalToLovelacePortion <$> parseFraction "softfork-init-thd" "Propose initial threshold (right after proposal is confirmed)")
           <*> (rationalToLovelacePortion <$> parseFraction "softfork-min-thd" "Propose minimum threshold (threshold can't be less than this)")
           <*> (rationalToLovelacePortion <$> parseFraction "softfork-thd-dec" "Propose threshold decrement (threshold will decrease by this amount after each epoch)")
        )

parseTxFeePolicy :: Parser (Maybe ParametersToUpdate)
parseTxFeePolicy = optional $
  TxFeePolicy . TxFeePolicyTxSizeLinear
    <$> ( TxSizeLinear <$> parseLovelace "tx-fee-a-constant" "Propose the constant a for txfee = a + b*s where s is the size"
                       <*> parseLovelace "tx-fee-b-constant" "Propose the constant b for txfee = a + b*s where s is the size"
        )

parseUnlockStakeEpoch :: Parser (Maybe ParametersToUpdate)
parseUnlockStakeEpoch = optional $
  UnlockStakeEpoch . EpochNumber
    <$> option auto
      ( long "unlock-stake-epoch"
      <> metavar "WORD64"
      <> help "Proposed epoch to unlock all stake."
      )