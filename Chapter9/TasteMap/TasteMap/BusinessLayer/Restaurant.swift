//
//  Restaurant.swift
//  TasteMap
//
//  Created by Kevin McNeish on 8/23/24.
//

import Foundation
import UIKit

private let rb = Restaurant<RestaurantEntity>()

enum RestaurantStatusColor {
    case open
    case closed
    case unknown
}

public class Restaurant<T: RestaurantEntity> : BusinessObject<T> {
        
    static var shared : Restaurant<RestaurantEntity> { return rb }
    
    // Override insertEntity to exclude invalid hours before inserting the entity
    override func insertEntity(_ entity: T) -> (state: SaveResult, message: String?) {
        
        // Filter out invalid operating hours (e.g., no open or closing time)
        let validHours = entity.hours?.filter { hours in
            guard let _ = hours.openTime, let _ = hours.closingTime else {
                return false // Exclude hours with missing open or close times
            }
            return true
        }
        
        // Set the filtered hours back to the restaurant entity
        entity.hours = validHours
        
        // Call the original insertEntity method to insert the entity
        return super.insertEntity(entity)
    }
    
    public func getOperatingHoursText(hours: [OperatingHoursEntity]?) -> (statusText: String, isOpen: Bool?) {
        guard let hours = hours else {
            return ("No operating hours available", nil)
        }

        let calendar = Calendar.current
        let now = Date()
        let currentDayOfWeek = calendar.component(.weekday, from: now)
        let currentTime = normalizeTime(date: now)

        var isOpen = false
        var closingTime: Date?
        var nextOpeningDay: String?
        var nextOpeningTime: Date?

        // Check if the restaurant is currently open
        for operatingHour in hours {
            if let dayOfWeek = operatingHour.dayOfWeek, dayOfWeek == currentDayOfWeek {
                if let openTime = operatingHour.openTime, let closeTime = operatingHour.closingTime {
                    let normalizedOpenTime = normalizeTime(date: openTime)
                    var normalizedCloseTime = normalizeTime(date: closeTime)

                    // If closing time is earlier than opening time, it means it closes on the next day
                    if normalizedCloseTime <= normalizedOpenTime {
                        normalizedCloseTime = normalizeTime(date: closeTime, withNextDay: true)
                    }

                    if currentTime >= normalizedOpenTime && currentTime < normalizedCloseTime {
                        isOpen = true
                        closingTime = normalizedCloseTime
                        break
                    }
                    else if currentTime < normalizedOpenTime {
                        // Restaurant opens later today
                        nextOpeningDay = nil // Indicating it opens today
                        nextOpeningTime = normalizedOpenTime
                        break
                    }
                }
            }
        }

        // If the restaurant is closed, find the next opening day/time
        if !isOpen && nextOpeningTime == nil {
            for i in 1...7 {
                let nextDayOfWeek = (currentDayOfWeek + i - 1) % 7 + 1
                if let nextOperatingHour = hours.first(where: {
                    if let dayOfWeek = $0.dayOfWeek {
                        return dayOfWeek == nextDayOfWeek
                    }
                    return false
                }) {
                    nextOpeningDay = calendar.weekdaySymbols[nextDayOfWeek - 1]
                    nextOpeningTime = normalizeTime(date: nextOperatingHour.openTime ?? now)
                    break
                }
            }
        }

        if isOpen, let closeTime = closingTime {
            let statusText = "Open - Closes \(timeString(from: closeTime))"
            return (statusText, true)
        }
        else if let nextOpeningTime = nextOpeningTime {
            if nextOpeningDay == nil {
                // Opens today, omit the day
                let statusText = "Closed - Opens at \(timeString(from: nextOpeningTime))"
                return (statusText, false)
            }
            else {
                // Opens on a future day, include the day
                let statusText = "Closed - Opens at \(timeString(from: nextOpeningTime)) on \(nextOpeningDay!)"
                return (statusText, false)
            }
        }
        else {
            return ("No operating hours available", nil)
        }
    }

    private func normalizeTime(date: Date, withNextDay: Bool = false) -> Date {
        let calendar = Calendar.current
        let normalizedDate = calendar.date(bySettingHour: calendar.component(.hour, from: date),
                                           minute: calendar.component(.minute, from: date),
                                           second: 0, of: Date()) ?? date
        if withNextDay {
            return calendar.date(byAdding: .day, value: 1, to: normalizedDate) ?? normalizedDate
        }
        return normalizedDate
    }

    private func closeTimeIsMidnight(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return components.hour == 0 && components.minute == 0
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

