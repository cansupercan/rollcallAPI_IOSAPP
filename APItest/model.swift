//
//  model.swift
//  APItest
//
//  Created by imac-3888 on 2025/12/19.
//

import Foundation

// MARK: - Base Response Structure
struct BaseResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
    let error: String?
}

// MARK: - Simple Response Structure (for APIs using status/message)
struct SimpleResponse: Codable {
    let status: String
    let message: String
    let token: String?
    let timestamp: String?
    let latitude: String?
    let longitude: String?
    let altitude: String?
    let note: String?
    let data: [AttendanceRecord]?
}

// MARK: - Event Registration Request
struct EventRegistrationRequest: Codable {
    let timestamp: String
    let latitude: String
    let longitude: String
    let altitude: String
    let note: String
}

// MARK: - User Check-in Request
struct UserCheckInRequest: Codable {
    let eventId: Int
    let name: String
}

// MARK: - Event Update Request
struct EventUpdateRequest: Codable {
    let id: Int
    let timestamp: String?
    let latitude: String?
    let longitude: String?
    let altitude: String?
    let note: String?
}

// MARK: - Event Info Response Data
struct EventInfo: Codable {
    let id: Int?
    let timestamp: String
    let latitude: String
    let longitude: String
    let altitude: String
    let note: String
}

// MARK: - Attendance Record
struct AttendanceRecord: Codable {
    let id: Int
    let name: String
    let success: Bool
    let note: String
}

// MARK: - All Events Response
struct AllEventsResponse: Codable {
    let status: String
    let message: String
    let data: [EventInfo]?
}

// MARK: - API Service Class
class APIService {
    static let shared = APIService()
    private let userDefaults = UserDefaults.standard
    private let baseURLKey = "APIBaseURL"
    
    private init() {}
    
    // MARK: - URL Management
    private var baseURL: String {
        get {
            return userDefaults.string(forKey: baseURLKey) ?? "http://localhost:8080"
        }
        set {
            userDefaults.set(newValue, forKey: baseURLKey)
        }
    }
    
    func getCurrentBaseURL() -> String {
        return baseURL
    }
    
    func getCurrentHost() -> String {
        return baseURL.replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: ":8080", with: "")
    }
    
    func updateBaseURL(host: String) {
        if host.hasPrefix("http://") {
            baseURL = host
        } else {
            baseURL = "http://\(host):8080"
        }
    }
    
    // MARK: - Test Connection
    func testConnection(completion: @escaping (Result<SimpleResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/test/test") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.unknown)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(SimpleResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Register Event
    func registerEvent(_ request: EventRegistrationRequest, completion: @escaping (Result<SimpleResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/event/register") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.unknown)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(SimpleResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Start Check-in (Get JWT Token)
    func startCheckIn(eventId: Int, completion: @escaping (Result<SimpleResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/event/action?eventId=\(eventId)") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.unknown)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(SimpleResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - User Check-in
    func userCheckIn(_ request: UserCheckInRequest, token: String, completion: @escaping (Result<SimpleResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/user/call") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.unknown)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(SimpleResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Get Event Info
    func getEventInfo(eventId: Int, token: String, completion: @escaping (Result<SimpleResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/event/info?eventId=\(eventId)") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.unknown)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(SimpleResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Get Event Attendees
    func getEventAttendees(eventId: Int, token: String, completion: @escaping (Result<SimpleResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/event/people?eventId=\(eventId)") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.unknown)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(SimpleResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Update Event
    func updateEvent(_ request: EventUpdateRequest, token: String, completion: @escaping (Result<SimpleResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/event/change") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.unknown)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(SimpleResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Delete User from Event
    func deleteUserFromEvent(eventId: Int, userId: Int, token: String, completion: @escaping (Result<SimpleResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/user/delete?eventId=\(eventId)&userId=\(userId)") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.unknown)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(SimpleResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Delete Event
    func deleteEvent(eventId: Int, completion: @escaping (Result<SimpleResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/event/delete?eventId=\(eventId)") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.unknown)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(SimpleResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Get All Events
    func getAllEvents(completion: @escaping (Result<AllEventsResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/event/all") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.unknown)))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(AllEventsResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
