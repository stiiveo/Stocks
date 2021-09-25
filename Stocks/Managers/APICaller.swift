//
//  APICaller.swift
//  Stocks
//
//  Created by Jason Ou on 2021/7/9.
//

import Foundation

struct APICaller {
    
    private struct Constants {
        
        static var apiKey = "PLACE-YOUR-API-KEY-HERE" // Place your own API Key here.
        
        static let baseUrl = "https://finnhub.io/api/v1/"
        static let secondsInADay: TimeInterval = 3600 * 24
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
    
    enum NewsType {
        case topStories, company(symbol: String)
    }
    
    func fetchNews(
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
    
    func fetchStockQuote(
        for symbol: String,
        completion: @escaping (Result<StockQuote, Error>) -> Void
    ) {
        let url = url(for: .quote, queryParams: ["symbol": symbol])
        request(url: url, expecting: StockQuote.self, completion: completion)
    }
    
    func fetchPriceHistory(
        _ symbol: String,
        timeSpan: CalendarManager.TimeSpan,
        completion: @escaping (Result<PriceHistoryResponse, Error>) -> Void
    ) {
        let calendar = CalendarManager()
        let startTime = Int(calendar.firstMarketOpenTime(timeSpan: timeSpan).timeIntervalSince1970)
        let endTime = Int(calendar.latestTradingTime.close.timeIntervalSince1970)
        let url = url(
            for: .stockCandles,
            queryParams: [
                "symbol": symbol,
                "resolution": timeSpan.dataResolution.rawValue,
                "from": "\(startTime)",
                "to": "\(endTime)"
            ]
        )
        request(url: url, expecting: PriceHistoryResponse.self, completion: completion)
    }
    
    /// Fetch specified company's financial metrics data: 52 week high, 52 week low, 10 day average trading volume etc.
    /// - Parameters:
    ///   - symbol: Symbol of the company.
    ///   - completion: A Metrics object is provided once the fetching process finishes successfully. An error object is provided otherwise.
    func fetchStockMetrics(
        symbol: String,
        completion: @escaping (Result<FinancialMetricsResponse, Error>) -> Void
    ) {
        let url = url(
            for: .metrics,
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
        case metrics = "stock/metric"
    }
    
    private var apiKey: String {
        return Constants.apiKey != "PLACE-YOUR-API-KEY-HERE" ? Constants.apiKey : Credentials.apiKey
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
        queryItems.append(.init(name: "token", value: apiKey))
        
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
    
    /// Error cases related to the API operations.
    enum APIError: Error {
        case noDataReturned
        case invalidUrl
        case noQuoteDataReturned
        case noPriceHistoryDataReturned
        case noQuoteAndPriceHistoryReturned
        case accessDenied
        case apiLimitReached
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
        
        let time = CalendarManager().currentNewYorkDate
        print(time, "| Request sent for type: \(type)")
        
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
                // Attempt to retrieve error message returned from API.
                do {
                    let explicitError = try JSONDecoder().decode(ExplicitApiError.self, from: data)
                    switch explicitError.error {
                    case "You don\'t have access to this resource.":
                        NotificationCenter.default.post(name: .dataAccessDenied, object: nil)
                        completion(.failure(APIError.accessDenied))
                    case "API limit reached. Please try again later. Remaining Limit: 0":
                        NotificationCenter.default.post(name: .apiLimitReached, object: nil)
                        completion(.failure(APIError.apiLimitReached))
                    default:
                        completion(.failure(explicitError))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    struct ExplicitApiError: Codable, Error {
        let error: String
    }
    
}
