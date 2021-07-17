//
//  APICaller.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import Foundation

final class APICaller {
    
    static let shared = APICaller()
    
    private struct Constants {
        static let apiKey = "c3khjtaad3i8d96s5cug"
        static let sandboxApiKey = "sandbox_c3khjtaad3i8d96s5cv0"
        static let baseUrl = "https://finnhub.io/api/v1/"
        static let day: TimeInterval = 3600 * 24
    }
    
    private init() {}
    
    // MARK: - Public
    
    /// Send search request to API with provided query string.
    /// - Parameters:
    ///   - query: "Searching keyword as query used to send API request."
    ///   - completion: Method to call after response from API is received. 
    func search(
        query: String,
        completion: @escaping (Result<SearchResponse, Error>) -> Void
    ) {
        guard let safeQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        request(
            url: url(
                for: .search,
                queryParams: ["q": safeQuery]
            ),
            expecting: SearchResponse.self,
            completion: completion
        )
        
    }
    
    public func fetchNews(
        for type: NewsViewController.`Type`,
        completion: @escaping (Result<[NewsStory], Error>) -> Void
    ) {
        switch type {
        case .topStories:
        request(
            url: url(for: .news, queryParams: ["category": "general"]),
            expecting: [NewsStory].self,
            completion: completion
        )
        case .company(let symbol):
            let today = Date()
            let oneMonthBack = today.addingTimeInterval(-(Constants.day * 7))
            request(
                url: url(
                    for: .companyNews,
                    queryParams: [
                        "symbol": symbol,
                        "from": DateFormatter.newsDateFormatter.string(from: oneMonthBack),
                        "to": DateFormatter.newsDateFormatter.string(from: today)
                    ]
                ),
                expecting: [NewsStory].self,
                completion: completion)
        }
    }
    
    /// Fetch specified stock's quote and candle sticks data from API.
    /// - Parameters:
    ///   - symbol: Symbol of the company.
    ///   - historyDuration: Number of days of candle sticks data to fetch.
    ///   - completion: A StockData object is provided once the fetching process succeeded. An error object is provided otherwise.
    public func fetchStockData(
        symbol: String,
        historyDuration days: TimeInterval,
        completion: @escaping (Result<StockData, Error>) -> Void
    ) {
        var stockQuote: StockQuote?
        var stockCandleSticks: [CandleStick]?
        let group = DispatchGroup()
        
        group.enter()
        getStockQuote(for: symbol) { result in
            defer {
                group.leave()
            }
            switch result {
            case .success(let response):
                stockQuote = response
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
        group.enter()
        getCandlesData(symbol, for: days) { result in
            defer {
                group.leave()
            }
            switch result {
            case .success(let response):
                stockCandleSticks = response.candleSticks
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
        group.notify(queue: .global(qos: .default)) {
            guard let quote = stockQuote,
                  let candleSticks = stockCandleSticks else {
                completion(.failure(APIError.failedToGetStockData))
                return
            }
            
            let stockData = StockData(quote: quote, candleSticks: candleSticks)
            completion(.success(stockData))
        }
    }
    
    /// Fetch specified company's financial metrics data: 52 week high, 52 week low, 10 day average trading volume etc.
    /// - Parameters:
    ///   - symbol: Symbol of the company.
    ///   - completion: A FinancialMetricsResponse object is provided once the fetching process finishes successfully. An error object is provided otherwise.
    public func fetchFinancialMetrics(
        symbol: String,
        completion: @escaping (Result<FinancialMetricsResponse, Error>) -> Void
    ) {
        let url = url(
            for: .financials,
            queryParams: ["symbol": symbol, "metric": "all"]
        )
        request(url: url, expecting: FinancialMetricsResponse.self, completion: completion)
    }
    
    // MARK: - Private
    
    /// Cases of the http endpoint of the API.
    private enum Endpoint: String {
        case search
        case news = "news"
        case companyNews = "company-news"
        case stockCandles = "stock/candle"
        case quote = "quote"
        case financials = "stock/metric"
    }
    
    /// Error cases related to the API operations.
    private enum APIError: Error {
        case noDataReturned
        case invalidUrl
        case failedToGetStockData
    }
    
    private func getStockQuote(
        for symbol: String,
        completion: @escaping (Result<StockQuote, Error>) -> Void
    ) {
        let url = url(for: .quote, queryParams: ["symbol": symbol])
        request(url: url, expecting: StockQuote.self, completion: completion)
    }
    
    private func getCandlesData(
        _ symbol: String,
        for numberOfDays: TimeInterval,
        completion: @escaping (Result<StockCandles, Error>) -> Void
    ) {
        let currentTime = Int(Date().timeIntervalSince1970)
        let startingTime = currentTime - Int(Constants.day * numberOfDays)
        let url = url(
            for: .stockCandles,
            queryParams: [
                "symbol": symbol,
                "resolution": "5",
                "from": "\(startingTime)",
                "to": "\(currentTime)"
            ]
        )
        request(url: url, expecting: StockCandles.self, completion: completion)
    }
    
    private func url(
        for endpoint: Endpoint,
        queryParams: [String: String] = [:]
    ) -> URL? {
        let urlString = Constants.baseUrl + endpoint.rawValue
        var queryItems = [URLQueryItem]()
        
        // Add parameters
        for (name, value) in queryParams {
            queryItems.append(.init(name: name, value: value))
        }
        
        // Add token
        queryItems.append(.init(name: "token", value: Constants.apiKey))
        
        // Convert query items to suffix string
        guard var components = URLComponents(string: urlString) else {
            print("Failed to create URLComponents object with provided url string (\(urlString)).")
            return nil
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            print("Failed to create url from URLComponents: \(components).")
            return nil
        }
        
        return url
    }
    
    private func request<T: Codable>(
        url: URL?,
        expecting type: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = url else {
            // Invalid url
            completion(.failure(APIError.invalidUrl))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(APIError.noDataReturned))
                }
                return
            }
            
            do {
                let result = try JSONDecoder().decode(type, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
}
