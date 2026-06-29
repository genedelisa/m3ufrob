// File: HTMLemitter.swift
// Project: m3ufrob
// Package: m3ufrob
// https://github.com/genedelisa/m3ufrob
// ~/Library/Developer/Xcode/UserData/IDETemplateMacros.plist
//
// Created by Gene De Lisa on 6/29/26
//
// Copyright © 2026 Rockhopper Technologies, Inc. All rights reserved.
// Licensed under the MIT License (the "License");
// You may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
// https://opensource.org/licenses/MIT
//
// Follow me on X: @GeneDeLisaDev


import Foundation

public struct HTMLEmitter {
    
    // MARK: - Function to run yt-dlp
    static func getDirectVideoURL(from pageURL: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["yt-dlp", "-g", pageURL]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
        } catch {
            print("❌ Failed to run yt-dlp for \(pageURL): \(error)")
            return nil
        }
        
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !output.isEmpty else {
            print("⚠️ No output from yt-dlp for \(pageURL)")
            return nil
        }
        
        // yt-dlp -g may return multiple lines (video, audio). Take first.
        if let firstLine = output.components(separatedBy: "\n").first {
            return firstLine
        }
        return nil
    }

    public static func displayPlaylistAsHTML(_ playlist:Playlist, path: String? = "index.html", comments: Bool = false) {
        
        
        // MARK: - Embedded CSS
        let embeddedCSS = """
body {
    font-family: Arial, sans-serif;
    background: #f4f4f4;
    margin: 0;
    padding: 20px;
}
.gallery {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 15px;
}
.gallery img {
    width: 100%;
    cursor: pointer;
    border-radius: 6px;
    transition: transform 0.2s;
}
.gallery img:hover {
    transform: scale(1.05);
}
.lightbox-overlay {
    position: fixed;
    top: 0; left: 0;
    width: 100vw; height: 100vh;
    background: rgba(0,0,0,0.85);
    display: none;
    justify-content: center;
    align-items: center;
    z-index: 1000;
    padding: 20px;
}
.lightbox-content {
    position: relative;
    max-width: 90%;
    max-height: 90%;
    display: flex;
    align-items: center;
}
.video-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    max-width: 800px;
    width: 100%;
}
.lightbox-content video {
    width: 100%;
    height: auto;
    border-radius: 8px;
    background: black;
}
#videoTitle {
    color: white;
    margin: 10px 0 5px;
    text-align: center;
}
#videoDesc {
    color: #ccc;
    font-size: 14px;
    text-align: center;
    max-width: 90%;
}
.lightbox-close {
    position: absolute;
    top: -40px;
    right: 0;
    font-size: 32px;
    color: white;
    background: none;
    border: none;
    cursor: pointer;
}
.lightbox-close:hover {
    color: #ccc;
}
.nav-btn {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    font-size: 40px;
    color: white;
    background: rgba(0,0,0,0.4);
    border: none;
    cursor: pointer;
    padding: 10px;
    border-radius: 50%;
    user-select: none;
}
.nav-btn:hover {
    background: rgba(0,0,0,0.6);
}
.prev-btn { left: -60px; }
.next-btn { right: -60px; }
@media (max-width: 600px) {
    .prev-btn, .next-btn {
        left: 10px;
        right: 10px;
        font-size: 30px;
    }
}
"""
        
        // MARK: - Resolve all direct URLs
        for i in playlist.sortedEntries.indices {
            print("🔍 Resolving direct URL for: \(playlist.sortedEntries[i].title)")
            if let direct = getDirectVideoURL(from: playlist.sortedEntries[i].urlString) {
                playlist.sortedEntries[i].directURLString = direct
                print("✅ Found direct URL")
            } else {
                print("❌ Could not get direct URL for \(playlist.sortedEntries[i].title)")
            }
        }
        
        
        // MARK: - Embedded JavaScript
        var embeddedJS = """
const videoData = [
"""
        for (i, video) in playlist.sortedEntries.enumerated() {
            embeddedJS += """
            {
            preview: \(video.extImgURLString),
            src: "\(video.directURLString)",
            title: "\(video.title)",
            desc: "\(video.title)"
            }\(i < playlist.sortedEntries.count - 1 ? "," : "")
            """
        }
        embeddedJS += """
        
];

const gallery = document.getElementById("gallery");
const lightbox = document.getElementById("lightbox");
const lightboxVideo = document.getElementById("lightboxVideo");
const videoTitle = document.getElementById("videoTitle");
const videoDesc = document.getElementById("videoDesc");
const closeBtn = document.getElementById("closeBtn");
const prevBtn = document.getElementById("prevBtn");
const nextBtn = document.getElementById("nextBtn");

let currentIndex = 0;

videoData.forEach((item, index) => {
    const img = document.createElement("img");
    img.src = item.preview;
    img.alt = item.title;
    img.addEventListener("click", () => openLightbox(index));
    gallery.appendChild(img);
});

function openLightbox(index) {
    currentIndex = index;
    updateLightbox();
    lightbox.style.display = "flex";
    lightboxVideo.play();
}

function closeLightbox() {
    lightbox.style.display = "none";
    lightboxVideo.pause();
    lightboxVideo.src = "";
}

function showPrev() {
    currentIndex = (currentIndex - 1 + videoData.length) % videoData.length;
    updateLightbox();
}

function showNext() {
    currentIndex = (currentIndex + 1) % videoData.length;
    updateLightbox();
}

function updateLightbox() {
    const video = videoData[currentIndex];
    lightboxVideo.pause();
    lightboxVideo.src = video.src;
    videoTitle.textContent = video.title;
    videoDesc.textContent = video.desc;
    lightboxVideo.play();
}

closeBtn.addEventListener("click", closeLightbox);
prevBtn.addEventListener("click", showPrev);
nextBtn.addEventListener("click", showNext);

lightbox.addEventListener("click", (e) => {
    if (e.target === lightbox) closeLightbox();
});

document.addEventListener("keydown", (e) => {
    if (lightbox.style.display === "flex") {
        if (e.key === "Escape") closeLightbox();
        if (e.key === "ArrowLeft") showPrev();
        if (e.key === "ArrowRight") showNext();
    }
});
"""
        
        
        
        // MARK: - HTML Start
        let htmlStart = """
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Video Lightbox with Navigation</title>
<style>
\(embeddedCSS)
</style>
</head>
<body>
"""
        
        // MARK: - HTML Body
        let htmlBody = """
<h1>Video Lightbox Gallery with Navigation</h1>

<div class="gallery" id="gallery"></div>

<!-- Lightbox -->
<div class="lightbox-overlay" id="lightbox">
    <div class="lightbox-content">
        <button class="lightbox-close" id="closeBtn">&times;</button>
        <button class="nav-btn prev-btn" id="prevBtn">&#10094;</button>
        <div class="video-container">
            <video id="lightboxVideo" controls></video>
            <h2 id="videoTitle"></h2>
            <p id="videoDesc"></p>
        </div>
        <button class="nav-btn next-btn" id="nextBtn">&#10095;</button>
    </div>
</div>

<script>
\(embeddedJS)
</script>

</body>
</html>
"""
        
        // MARK: - Combine and Write File
        let fullHTML = htmlStart + htmlBody
        
        do {
            try fullHTML.write(to: URL(fileURLWithPath: "index.html"), atomically: true, encoding: .utf8)
            print("✅ index.html generated successfully.")
        } catch {
            print("❌ Error writing HTML file: \(error)")
        }
    }
}
