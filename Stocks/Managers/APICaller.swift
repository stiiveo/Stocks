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
        static let secondsInADay: TimeInterval = 3600 * 24
    }
    
    private init() {}
    
    // MARK: - Public
    
    /// Send search request to API with provided query string.
    /// - Parameters:
    ///   - query: "Searching keyword as query used to send API request."
    ///   - completion: Method to call after response from API is received. 
    public func search(
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
    
    enum NewsType {
        case topStories, company(symbol: String)
    }
    
    public func fetchNews(
        for type: NewsType,
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
            let now = Date()
            let startTime = now.addingTimeInterval(-(Constants.secondsInADay * 7))
            request(
                url: url(
                    for: .companyNews,
                    queryParams: ["symbol": symbol,
                                  "from": DateFormatter.newsDateFormatter.string(from: startTime),
                                  "to": DateFormatter.newsDateFormatter.string(from: now)]
                ),
                expecting: [NewsStory].self,
                completion: completion
            )
        }
    }
    
    /// Fetch specified stock's quote and candle sticks data from API.
    /// - Parameters:
    ///   - symbol: Symbol of the company.
    ///   - historyDuration: Number of days of candle sticks data to fetch.
    ///   - completion: A StockData object is provided once the fetching process succeeded. An error object is provided otherwise.
    public func fetchStockData(
        symbol: String,
        historyDuration days: Int,
        completion: @escaping (Result<StockData, Error>) -> Void
    ) {
        var stockQuote: StockQuote?
        var stockPriceHistory: [PriceHistory]?
        let group = DispatchGroup()
        
        group.enter()
        fetchStockQuote(for: symbol) { result in
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
        fetchPriceHistory(symbol, dataResolution: .fiveMinutes, days: days) { result in
            defer {
                group.leave()
            }
            switch result {
            case .success(let response):
                stockPriceHistory = response.priceHistory
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
        group.notify(queue: .global(qos: .default)) {
            guard let quote = stockQuote,
                  let priceHistory = stockPriceHistory else {
                completion(.failure(APIError.failedToGetStockData))
                return
            }
            
            let stockData = StockData(quote: quote, priceHistory: priceHistory)
            completion(.success(stockData))
        }
    }
    
    public func fetchStockQuote(
        for symbol: String,
        completion: @escaping (Result<StockQuote, Error>) -> Void
    ) {
        let url = url(for: .quote, queryParams: ["symbol": symbol])
        request(url: url, expecting: StockQuote.self, completion: completion)
    }
    
    /// Time interval between each data set.
    enum DataResolution: String {
        case minute = "1"
        case fiveMinutes = "5"
        case fifteenMinutes = "15"
        case thirtyMinutes = "30"
        case hour = "60"
        case day = "D"
        case week = "W"
        case month = "M"
    }
    
    public func fetchPriceHistory(
        _ symbol: String,
        dataResolution resolution: DataResolution,
        days: Int,
        completion: @escaping (Result<StockCandlesResponse, Error>) -> Void
    ) {
        let calendarManager = CalendarManager()
        let currentTime = Int(calendarManager.latestTradingTimeInterval.1)
        let startingTime = Int(calendarManager.latestTradingTimeInterval.0)
        let url = url(
            for: .stockCandles,
            queryParams: [
                "symbol": symbol,
                "resolution": resolution.rawValue,
                "from": "\(startingTime)",
                "to": "\(currentTime)"
            ]
        )
        request(url: url, expecting: StockCandlesResponse.self, completion: completion)
    }
    
    /// Fetch specified company's financial metrics data: 52 week high, 52 week low, 10 day average trading volume etc.
    /// - Parameters:
    ///   - symbol: Symbol of the company.
    ///   - completion: A Metrics object is provided once the fetching process finishes successfully. An error object is provided otherwise.
    public func fetchStockMetrics(
        symbol: String,
        completion: @escaping (Result<Metrics, Error>) -> Void
    ) {
        let url = url(
            for: .metrics,
            queryParams: ["symbol": symbol, "metric": "all"]
        )
        request(url: url, expecting: Metrics.self, completion: completion)
    }
    
    // MARK: - Private
    
    /// Cases of the http endpoint of the API.
    private enum Endpoint: String {
        case search
        case news = "news"
        case companyNews = "company-news"
        case stockCandles = "stock/candle"
        case quote = "quote"
        case metrics = "stock/metric"
    }
    
    /// Error cases related to the API operations.
    private enum APIError: Error {
        case noDataReturned
        case invalidUrl
        case failedToGetStockData
    }
    
    private func url(
        for endpoint: Endpoint,
        queryParams: [String: String] = [:]
    ) -> URL? {
        let urlString = Constants.baseUrl + endpoint.rawValue
        var queryItems = queryParams.map(
            { URLQueryItem(name: $0.key, value: $0.value) }
        )
        // Add token query item.
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
