from brownie import MultiSigWallet, accounts


def main():
    account = accounts.load("deployment_account")
    MultiSigWallet.deploy({"from": account})
