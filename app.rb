require 'nokogiri'
require 'open-uri'
require 'sinatra'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

get '/fund/:ticket' do
  ticket = params['ticket']

  url = "https://www.fundsexplorer.com.br/funds/#{ticket}"

  begin
    doc = Nokogiri::HTML(URI.open(url))

    def clean_text(item, key)
      item.gsub!(/\s+/, "") if key != :nome and key != :segmento
      item.sub!('DividendYieldde', "") if key == :dividend_yield
      item = item.match(/(\d+,\d+\w)/)[0] if key == :liquidez_diaria
      item = item.match(/(R\$\d+,\d+\w)/)[0] if key == :patrimonio_liquido
      item
    end

    data = {
      nome: '#carbon_fields_fiis_header-2 > div > div > div.headerTicker__content > p',
      codigo: '#tickerName',
      dividendo: '#carbon_fields_fiis_dividends_resume-2 > div > div.txt > p:nth-child(1) > b:nth-child(2)',
      dividend_yield: '#carbon_fields_fiis_dividends_resume-2 > div > div.txt > p:nth-child(1) > b:nth-child(4)',
      pvp: '#indicators > div:nth-child(7) > p:nth-child(2) > b',
      preco: '#carbon_fields_fiis_dividends_resume-2 > div > div.txt > p:nth-child(2) > b:nth-child(4)',
      valor_patrimonial: '#indicators > div:nth-child(5) > p:nth-child(2) > b',
      rentabilidade_no_mes: '#indicators > div:nth-child(6) > p:nth-child(2) > b',
      cotas_emitidas: '#carbon_fields_fiis_basic_informations-2 > div > div > div:nth-child(8) > p:nth-child(2) > b',
      segmento: '#carbon_fields_fiis_basic_informations-2 > div > div > div:nth-child(6) > p:nth-child(2) > b',
      liquidez_diaria: '#indicators > div:nth-child(1) > p:nth-child(2) > b',
      patrimonio_liquido: '#indicators > div:nth-child(4) > p:nth-child(2) > b'
    }

    fund = data.map do |key, value|
      item = doc.css(value).text
      item = clean_text(item, key)
      [key, item]
    end.to_h

    content_type :json
    fund.to_json
  rescue OpenURI::HTTPError => e
    if e.io.status[0] == "404"
      content_type :json
      { error: "Ticket #{ticket.upcase} não existente" }.to_json
    else
      halt 500
    end
  end
end