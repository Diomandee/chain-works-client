import { useState } from "react";
import {
  ContractCallRegularOptions,
  openContractCall,
  UserData,
} from "@stacks/connect";
import { StacksMocknet } from "@stacks/network";
import { standardPrincipalCV, uintCV } from "@stacks/transactions";
import { appDetails, contractOwnerAddress } from "../../lib/constant";

export default function CreateParent() {
  const [exchangeToken, setExchangeToken] = useState("");
  const [mintAmount, setMintAmount] = useState(1000000);

  const mintTokens = async (e: React.MouseEvent<HTMLButtonElement>) => {
    e.preventDefault();
    console.log(`Minting ${mintAmount} of ${exchangeToken}`);
  };

  return (
    <div className="flex flex-col items-stretch max-w-4xl gap-8 m-auto">
      {/* <Auth /> */}

      <form className="flex flex-col gap-4">
        <div>
          <label
            htmlFor="exchange-token"
            className="block text-sm font-medium text-gray-700"
          >
            Exchange Token
          </label>
          <div className="mt-1">
            <input
              type="text"
              id="exchange-token"
              onChange={(e) => setExchangeToken(e.target.value)}
              className="block w-full p-2 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              placeholder="some-token"
            />
          </div>
        </div>

        <div>
          <label
            htmlFor="mint-amount"
            className="block text-sm font-medium text-gray-700"
          >
            Mint Amount
          </label>
          <div className="mt-1">
            <div
              name="mint-amount"
              decimals={0}
              required={false}
              defaultValue={mintAmount}
              onChange={(e) => setMintAmount(e.target.valueAsNumber)}
            />
          </div>
        </div>

        <div className="flex flex-row gap-8">
          <button type="button" disabled={!exchangeToken} onClick={mintTokens}>
            Mint Tokens
          </button>
        </div>
      </form>
    </div>
  );
}
