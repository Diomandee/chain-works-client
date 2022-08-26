import React, { useState, useEffect } from "react";
import {
  Steps,
  Result,
  Layout,
  Form,
  Input,
  Button,
  InputNumber,
  Col,
  Select,
  DatePicker,
  Spin,
  Row,
} from "antd";
import { SmileOutlined, SmileTwoTone } from "@ant-design/icons";
import { useSelector, useDispatch } from "react-redux";
import { createStream } from "../../actions";
import { Link } from "react-router-dom";
import { Connect } from "@stacks/connect-react";
import { useConnect } from "../Auth";
import { connectWallet } from "../../actions";
import { loginStatusAtom } from "../../components/store/stacks";
import { StacksTestnet, StacksMocknet, StacksMainnet } from "@stacks/network";
import { appDetails, contractOwnerAddress } from "../../lib/constant";
import * as c32 from "c32check";
import { useAtom } from "jotai";
import { useMemo } from "react";
import { stxAddressAtom, stxBnsNameAtom } from "../../components/store/stacks";
import {
  AppConfig,
  UserSession,
  showConnect,
  openContractCall,
} from "@stacks/connect";
import {
  // uintCV,
  // intCV,
  bufferCV,
  // stringAsciiCV,
  // stringUtf8CV,
  postConditionMode,
  makeSTXTokenTransfer,
  ClarityAbi,
  standardPrincipalCV,
  // trueCV,
  makeStandardSTXPostCondition,
  FungibleConditionCode,
  // PostConditionMode,
  listCV,
  broadcastTransaction,
  tupleCV,
  contractPrincipalCV,
  uintCV,
  // createSTXPostCondition,
  parsePrincipalString,
  StacksMessageType,
  PostConditionType,
} from "@stacks/transactions";

const testnet = new StacksTestnet();
let activeNetwork = testnet;

const { Step } = Steps;
const { Content } = Layout;
const { Option } = Select;
const { RangePicker } = DatePicker;

const appConfig = new AppConfig(["store_write", "publish_data"]);
const userSession = new UserSession({ appConfig });

const rangeConfig = {
  rules: [{ type: "array", required: true, message: "Please select time!" }],
};

const CreateStream = (props) => {
  const [user, setUser] = useState();
  const [currentStep, setCurrentStep] = useState(0);
  const [token, setToken] = useState();
  const dispatch = useDispatch();
  const [form] = Form.useForm();
  const [amount, setAmount] = useState("");
  const [address, setAddress] = useState("");
  const [owner, setOwner] = useState();
  const [closingTime, setclosingTime] = useState("");
  const [range, setRange] = useState();
  const [loader, setLoader] = useState(false);
  const selector = useSelector((state) => state.createStream);
  const selector2 = useSelector((state) => state.walletConfig);

  const { handleOpenAuth } = useConnect();
  const [loginStatus] = useAtom(loginStatusAtom);
  const network = new StacksTestnet();

  useEffect(() => {
    if (loginStatus) setCurrentStep(2);
  }, [loginStatus]);

  // useEffect(() => {
  //   dispatch({ type: "CLEAR_RESPONSE" });
  //   setLoader(false);
  //   setCurrentStep(0);
  // }, []);

  useEffect(() => {
    if (currentStep === 1) {
      setCurrentStep(2);
    }
    setRange(undefined);
    setAddress("");
    setAmount("");
    setToken(undefined);
    setLoader(false);
  }, [selector]);

  const handleOnClick = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    console.log(e);
    // const address = userData?.profile?.stxAddress?.testnet;
    let stxcontractaddres = "STJX0CBMKJGRWR4PNQFWRXJ2H9878XE55AV29D0W"; //mocknet
    let address_1 = "ST59YR7W1J8MRD1D21TE2YJCSXQ9FBT7SCW88PEB";
    let address_2 = "ST17YAH0GBG3MYMXNV86XJGZCWPC8PBC0AWBDV0ZW";
    let address_3 = "ST220FD5JTSPRCZ8CPN3B6313C5RYM58SYMCQAZYY";
    let address_4 = "ST2N6D04004BYC17MXRWS5BX1XMC0E84C3542X76D";
    let stxcontractname = "Chain-Works-V1";

    const Address = () => {
      const [stxAddress] = useAtom(stxAddressAtom);
      const displayAddress = useMemo(() => {
        if (stxAddress.loaded)
          return `${stxAddress.data.substring(
            0,
            5
          )}...${stxAddress.data.substring(stxAddress.data.length - 5)}`;
        return "Profile";
      }, [stxAddress]);
    };

    const txOptions = {
      contractAddress: stxcontractaddres,
      contractName: stxcontractname,
      functionName: "create-parent",
      functionArgs: [
        Address(standardPrincipalCV(stxcontractaddres)),
        Address(
          listCV([
            standardPrincipalCV(address_1),
            standardPrincipalCV(address_2),
            standardPrincipalCV(address_3),
            standardPrincipalCV(address_4),
          ])
        ),
        uintCV(amount * 1000000),
        uintCV(closingTime),
      ],

      network,
      postConditions: [],
      onFinish: (data) => {
        console.log("onFinish:", data);
      },
    };
    const transaction = makeSTXTokenTransfer(txOptions);
  };

  // to see the raw serialized tx

  // broadcasting transaction to the specified network
  // const broadcastResponse = broadcastTransaction(transaction);
  // const txId = broadcastResponse.txid;

  const stepContent = [
    <Result
      icon={<SmileOutlined />}
      extra={
        loginStatus ? (
          <Button type="primary" onClick={() => setCurrentStep(1)}>
            Next
          </Button>
        ) : (
          <Button type="primary" onClick={handleOpenAuth}>
            Connect wallet and Continue
          </Button>
        )
      }
    />,

    <Result icon={<SmileTwoTone />} title="">
      <Spin spinning={loader}>
        <Form
          form={form}
          labelCol={{ span: 5 }}
          wrapperCol={{ span: 16 }}
          initialValues={{ remember: true }}
        >
          <Form.Item
            label="Token"
            rules={[{ required: true, message: "Please Select Token!" }]}
          >
            <Select
              placeholder="Select Token you want to stream"
              onChange={setToken}
              value={token}
              allowClear
            >
              <Option value="SOL">SOL</Option>
            </Select>
          </Form.Item>
          {/* <Row justify="space-around"> */}
          <Form.Item
            label="Deposit"
            rules={[{ required: true, message: "Enter a valid rate" }]}
          >
            <InputNumber
              value={amount}
              placeholder="Amount in STX"
              onChange={(e) => setAmount(e)}
            />
          </Form.Item>
          <Form.Item
            label="Closing Time"
            rules={[{ required: true, message: "Enter a valid rate" }]}
          >
            <InputNumber
              value={closingTime}
              placeholder="Closing Time"
              onChange={(e) => setclosingTime(e)}
            />
            <Form.Item
              label="Recipient"
              rules={[
                {
                  required: true,
                  message: "Enter a valid address",
                },
              ]}
            ></Form.Item>

            <Input
              value={address}
              placeholder="Enter the address of recipient."
              onChange={(e) => setAddress(e.target.value)}
            />
          </Form.Item>

          <Form.Item wrapperCol={{ offset: 10, span: 16 }}>
            <Button type="primary" htmlType="submit" onClick={handleOnClick}>
              Submit
            </Button>
            <Button
              style={{ marginLeft: "5px" }}
              type="primary"
              onClick={() => {
                setCurrentStep(0);
              }}
            >
              Back
            </Button>
          </Form.Item>
        </Form>
      </Spin>
    </Result>,
    selector.result ? (
      <Result
        status="success"
        title="Succesfully created stream"
        subTitle={`Stream ID ${selector.id}`}
        extra={[
          <Button
            type="primary"
            key="Check_stream"
            onClick={() => props.setKey("2")}
          >
            <Link to="/sending">Check stream</Link>
          </Button>,
          <Button
            type="secondary"
            key="create_another"
            onClick={(e) => {
              e.preventDefault();
              setCurrentStep(0);
            }}
          >
            Create Another
          </Button>,
        ]}
      />
    ) : (
      <Result
        status="error"
        title="Some error occured"
        subTitle="Please check and modify the information and try agan."
        extra={[
          <Button
            type="primary"
            key="try_again"
            onClick={(e) => {
              e.preventDefault();
              setCurrentStep(0);
            }}
          >
            Try Again
          </Button>,
        ]}
      ></Result>
    ),
  ];

  return (
    <div>
      <Col className="site-page-header">
        <h3 className="page-heading">
          Stream Tokens
          <br />
          <div className="page-sub-heading">
            Just follows two simple steps to start streaming SOL.
          </div>
        </h3>
      </Col>
      <div
        className="create-stream-steps"
        style={{
          width: "100%",
          height: "80vh",
          padding: 20,
        }}
      >
        <Steps className="steps" current={currentStep}>
          {/* <Step title="Step 1" description="Confirmation" /> */}
          <Step title="Step 2" description="Fill the details" />
          <Step title="Step 3" description="All Done!" />
        </Steps>
        <Content className="form-content">{stepContent[currentStep]}</Content>
      </div>
    </div>
  );
};
export default CreateStream;
// if (range !== undefined && amount !== 0 && address !== "") {
//   setLoader(true);
//   dispatch(
//     createStream({
//       receiverAddress: address,
//       startTime: range[0].unix(),
//       endTime: range[1].unix(),
//       amountSpeed: amount,
//     })
//   );
// }
// form.resetFields();
// setRange(undefined);
// setAddress("");
// setAmount("");
// setclosingTime("");
// setToken(undefined);
