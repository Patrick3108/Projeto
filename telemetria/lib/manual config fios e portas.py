import os
from weasyprint import HTML

html_content = """
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<style>
    @page {
        size: A4;
        margin: 15mm 20mm;
        background-color: #fcfbf9;
    }
    * {
        box-sizing: border-box;
    }
    body {
        font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
        color: #333;
        margin: 0;
        padding: 0;
        line-height: 1.6;
        font-size: 11pt;
    }
    h1 {
        color: #1a365d;
        font-size: 22pt;
        border-bottom: 2px solid #3182ce;
        padding-bottom: 8px;
        margin-bottom: 24px;
        page-break-after: avoid;
    }
    h2 {
        color: #2b6cb0;
        font-size: 14pt;
        margin-top: 24px;
        padding-left: 10px;
        border-left: 4px solid #3182ce;
        page-break-after: avoid;
    }
    h3 {
        color: #2d3748;
        font-size: 12pt;
        margin-top: 16px;
        page-break-after: avoid;
    }
    p {
        margin-bottom: 12px;
    }
    ul {
        margin-bottom: 16px;
        padding-left: 24px;
    }
    li {
        margin-bottom: 6px;
    }
    table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 20px;
        background-color: #fff;
    }
    th, td {
        border: 1px solid #cbd5e0;
        padding: 10px;
        text-align: left;
    }
    th {
        background-color: #ebf8ff;
        color: #2a4365;
        font-weight: bold;
    }
    .warning-box {
        background-color: #fffaf0;
        border-left: 4px solid #dd6b20;
        padding: 12px 16px;
        margin: 16px 0;
        page-break-inside: avoid;
    }
    .code-block {
        background-color: #2d3748;
        color: #f7fafc;
        padding: 12px;
        border-radius: 4px;
        font-family: 'Courier New', Courier, monospace;
        font-size: 10pt;
        white-space: pre-wrap;
        margin-bottom: 16px;
        page-break-inside: avoid;
    }
    .highlight {
        font-weight: bold;
        color: #e53e3e;
    }
</style>
</head>
<body>

    <h1>Manual de Integração: MCP2515 + Display XPT2046 no Raspberry Pi 5</h1>
    
    <p>Este documento detalha a solução para a integração física e de software do módulo CAN MCP2515 em um Raspberry Pi 5 que já possui um display Waveshare de 5 polegadas (XPT2046) acoplado, resolvendo conflitos de hardware e detalhando o uso de componentes auxiliares.</p>

    <h2>1. Análise de Conflito de Pinos (Display vs. MCP2515)</h2>
    <p>O display Waveshare de 5 polegadas com touch capacitivo/resistivo (controlador XPT2046) utiliza a interface SPI principal (SPI0) do Raspberry Pi para processar os toques na tela. Ele fisicamente encaixa sobre os primeiros 26 pinos do conector GPIO.</p>
    <ul>
        <li><strong>Conflito de Pinos:</strong> O display ocupa os pinos 19 (MOSI), 21 (MISO), 23 (SCK), 24 (CE0) e 26 (CE1). Além disso, o pino 22 (GPIO 25) costuma ser usado para a interrupção do Touch (TP_IRQ).</li>
        <li><strong>Solução recomendada:</strong> Para evitar conflitos de software e facilitar o acesso físico, transferiremos o MCP2515 para o barramento secundário <strong>SPI1</strong>, utilizando os pinos do final da barra de GPIO (pinos 27 a 40), que ficam parcialmente livres na borda do display.</li>
    </ul>

    <h2>2. Acesso Físico e Uso da Protoboard SYB-120</h2>
    <p>Sim, você pode e deve usar a sua protoboard SYB-120 para organizar essas ligações. No entanto, como o display cobre os pinos do Pi, você precisará de uma estratégia de acesso:</p>
    <ul>
        <li><strong>Cabo Extensor (Ribbon Cable) ou Stacking Header:</strong> Recomenda-se colocar um conector empilhável (stacking header) entre o Pi e o display, ou usar um cabo extensor para levar os pinos até a SYB-120. A partir da protoboard, o display e o módulo CAN podem ser cabeados separadamente.</li>
        <li><strong>Uso de cabos Dupont 90°:</strong> Se os pinos 27 a 40 estiverem acessíveis abaixo da borda do display, cabos flexíveis curvos podem ser encaixados diretamente para puxar as vias SPI1 para a protoboard.</li>
    </ul>

    <h2>3. Identificação da Placa Menor (TX/RX para CAN)</h2>
    <div class="warning-box">
        <strong>Aviso Importante sobre Tensão:</strong> A placa que possui os pinos <code>CANH, CANL</code> de um lado e <code>VCC, TX, RX, GND</code> do outro <strong>NÃO</strong> é um regulador de tensão.
    </div>
    <p>Trata-se de um <strong>Transceptor CAN isolado</strong> (como o módulo SN65HVD230 ou TJA1050 breakout). Sendo um entusiasta de eletrônica e projetos DIY com microcontroladores (como a linha ESP32), este módulo é comumente utilizado em suas aplicações onde o controlador (ESP) já possui suporte a protocolo CAN interno, necessitando apenas da camada física (Transceiver) para enviar os diferenciais para a rede (CANH/CANL).</p>
    <p>Como o MCP2515 já vem com esse transceptor embutido na mesma placa, você não precisa ligar essa placa pequena neste circuito. Para resolver a tensão lógica de 3.3V do Raspberry Pi com os 5V do MCP2515, faça um divisor de tensão com resistores simples no pino MISO (SO), reduzindo o sinal que volta para o Pi, ou utilize um "Logic Level Converter" bidirecional na protoboard SYB-120.</p>

    <h2>4. Novo Mapa de Conexões (Utilizando SPI1)</h2>
    <p>Utilizaremos os pinos finais do Raspberry Pi 5, roteando para a protoboard.</p>
    <table>
        <thead>
            <tr>
                <th>Pino Módulo MCP2515</th>
                <th>Pino Físico (Board) no RPi 5</th>
                <th>Função Alternativa</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><strong>VCC</strong></td>
                <td>Pino 2 ou 4 (Via Protoboard)</td>
                <td>Alimentação 5V (Atenção ao divisor de tensão no SO)</td>
            </tr>
            <tr>
                <td><strong>GND</strong></td>
                <td>Pino 39</td>
                <td>Ground</td>
            </tr>
            <tr>
                <td><strong>CS</strong></td>
                <td>Pino 36</td>
                <td>GPIO 16 (SPI1 CE0)</td>
            </tr>
            <tr>
                <td><strong>SI</strong></td>
                <td>Pino 38</td>
                <td>GPIO 20 (SPI1 MOSI)</td>
            </tr>
            <tr>
                <td><strong>SO</strong></td>
                <td>Pino 35</td>
                <td>GPIO 19 (SPI1 MISO)</td>
            </tr>
            <tr>
                <td><strong>SCK</strong></td>
                <td>Pino 40</td>
                <td>GPIO 21 (SPI1 SCLK)</td>
            </tr>
            <tr>
                <td><strong>INT</strong></td>
                <td>Pino 32</td>
                <td>GPIO 12 (Pino de Interrupção Livre)</td>
            </tr>
        </tbody>
    </table>

    <h2>5. Configuração de Software (com Cristal de 8MHz)</h2>
    <p>Para ativar a interface SPI1 e configurar o driver para a frequência correta, você deverá editar o arquivo de boot do Raspberry Pi. Abra o terminal e edite o arquivo:</p>
    <div class="code-block">sudo nano /boot/firmware/config.txt</div>
    <p>Adicione (ou altere) as seguintes linhas, garantindo a configuração específica de 8MHz (8000000) registrada para o seu hardware e os novos pinos do SPI1:</p>
    <div class="code-block"># Habilitar barramentos SPI
dtparam=spi=on
dtoverlay=spi1-1cs

# Configurar o MCP2515 no SPI1 com cristal de 8MHz e interrupcao no GPIO 12
dtoverlay=mcp2515-can1,oscillator=8000000,interrupt=12,spimaxfrequency=1000000</div>
    
    <p>Após salvar as alterações (Ctrl+O, Enter, Ctrl+X), reinicie o Raspberry Pi para que o overlay seja ativado sem interferir na placa XPT2046 do seu display.</p>

</body>
</html>
"""

html_path = "/tmp/Manual_MCP2515_Display_Conflitos.html"
pdf_path = "/tmp/Manual_Conexao_CAN_RaspberryPi5.pdf"

with open(html_path, "w") as f:
    f.write(html_content)

HTML(filename=html_path).write_pdf(pdf_path)
print(f"PDF_GENERATED: {pdf_path}")