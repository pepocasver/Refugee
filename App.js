import React, { useState, useEffect } from 'react';
import RefuToken from "./contracts/RefuToken.json";
import './App.css';

// Importar web3
import Web3 from 'web3';



function App() {
  const [web3, setWeb3] = useState(null);
  const [accounts, setAccounts] = useState([]);
  const [selectedAccount, setSelectedAccount] = useState(null);
  const [contract, setContract] = useState(null);
  const [network, setNetwork] = useState(null);
  const [investmentAmount, setInvestmentAmount] = useState('');
  const [transactionStatus, setTransactionStatus] = useState('');

  useEffect(() => {
    // Cargar Web3
    const loadWeb3 = async () => {
      if (window.ethereum) {
        const web3Instance = new Web3(window.ethereum);
        setWeb3(web3Instance);

        try {
          // Solicitar acceso a la billetera
          await window.ethereum.enable();

          // Obtener cuentas
          const accounts = await web3Instance.eth.getAccounts();
          setAccounts(accounts);

          const networkId = await web3Instance.eth.net.getId(); //to get contract address

          // Establecer cuenta seleccionada
          setSelectedAccount(accounts[0]);

         // Crear instancia del contrato
           
          const deployedNetwork = RefuToken.networks[networkId];
          console.log(deployedNetwork.address);
          const contractInstance = new web3Instance.eth.Contract(RefuToken.abi, deployedNetwork.address);
          setContract(contractInstance);
          setNetwork(networkId);

          // Detectar cambios de cuenta
          window.ethereum.on('accountsChanged', function (newAccounts) {
            setAccounts(newAccounts);
            setSelectedAccount(newAccounts[0]);
          });
        } catch (error) {
          console.error('Usuario denegó el acceso a la billetera', error);
        }
      } else {
        console.error('MetaMask no está instalado');
      }
    };

    loadWeb3();
  }, []);

  // Función para conectar la billetera
  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        await window.ethereum.request({ method: 'eth_requestAccounts' });
        const accounts = await web3.eth.getAccounts();
        setAccounts(accounts);
        setSelectedAccount(accounts[0]);
      } catch (error) {
        console.error('Error al conectar la billetera:', error);
      }
    }
  };

  // Función para interactuar con el contrato
  const interactWithContract = async () => {
    if (contract) {
      try {
        // Ejemplo: Llamar a una función del contrato
        const result = await contract.methods.miFuncion().call();
        console.log('Resultado de la función del contrato:', result);
      } catch (error) {
        console.error('Error al interactuar con el contrato:', error);
      }
    }
  };

    // Función para interactuar con el contrato e invertir tokens
    const invertirTokens = async () => {
      if (contract && investmentAmount !== '' && !isNaN(investmentAmount)) {
        try {
          // Convertir la cantidad de inversión a Wei (la unidad más pequeña de Ethereum)
          const investmentWei = web3.utils.toWei(investmentAmount.toString(), 'ether');
  
          // Enviar la transacción al contrato para invertir tokens
          const result = await contract.methods.invertirTokens(investmentWei).send({ from: selectedAccount });
  
          // Actualizar el estado de la transacción
          setTransactionStatus('Transacción exitosa: ' + result.transactionHash);
        } catch (error) {
          console.error('Error al invertir tokens:', error);
          setTransactionStatus('Error: ' + error.message);
        }
      } else {
        setTransactionStatus('Por favor, ingrese una cantidad válida');
      }
    };
  
    // Función para manejar cambios en el campo de entrada de inversión
    const handleInvestmentChange = (event) => {
      setInvestmentAmount(event.target.value);
    };

  return (
    <div className="App">
      <header>
        <nav>
          <ul>
            <li><a href="#">About Us</a></li>
            <li><a href="#">Social Impact</a></li>
            <li><a href="#">Contact Us</a></li>
            <li><a href="#">Login</a></li>
            <li><a href="#">Register</a></li>
          </ul>
        </nav>
      </header>
      <main>
        <section className="wallet-section">
          <h2>Connect to Wallet</h2>
          {web3 && accounts.length > 0 ? (
            <p>Billetera conectada. Cuenta seleccionada: {selectedAccount}</p>
          ) : (
            <button onClick={connectWallet}>Connect your Wallet</button>
          )}
          <button onClick={interactWithContract}>Interact with Contract</button>
          
          <button onClick={invertirTokens}>Invertir Tokens</button>
          <input
            type="text"
            value={investmentAmount}
            onChange={handleInvestmentChange}
            placeholder="Cantidad de tokens a invertir"
          />
          <p>{transactionStatus}</p>
        
        </section>
      </main>
    </div>
  );
}

export default App;
