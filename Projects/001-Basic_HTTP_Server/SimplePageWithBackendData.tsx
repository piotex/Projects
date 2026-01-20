import React, { useState, useEffect } from "react";

const SimplePageWithBackendData = () => {
  const [time, setTime] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let intervalId: NodeJS.Timeout;

    async function fetchData() {
      try {
        const response = await fetch("http://127.0.0.1:8090/");
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        const dateString = data.time;
        const now = new Date(dateString);
        const timeOnly = now.toLocaleTimeString();
        setTime(timeOnly);
        setError(null);
      } catch (err: any) {
        setError(err.message);
        setTime(null);
      }
    }

    fetchData();
    intervalId = setInterval(fetchData, 1000);

    return () => clearInterval(intervalId);
  }, []);

  return (
    <div
      style={{
        fontFamily: "Arial, sans-serif",
        backgroundColor: "#f4f6f8",
        color: "#333",
        margin: 0,
        padding: 20,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        height: "100vh",
        justifyContent: "center",
      }}
    >
      <h1 style={{ color: "#007acc", marginBottom: 20 }}>Data from Backend</h1>
      <div
        id="data-container"
        style={{
          backgroundColor: "#ffffff",
          padding: "20px 30px",
          borderRadius: 8,
          boxShadow: "0 0 10px rgba(0, 0, 0, 0.1)",
          fontSize: 18,
          minWidth: 300,
          textAlign: "center",
        }}
      >
        {error ? (
          <p>Error fetching data: {error}</p>
        ) : time ? (
          <p>{time}</p>
        ) : (
          <p>Loading data...</p>
        )}
      </div>
    </div>
  );
};

export default SimplePageWithBackendData;
