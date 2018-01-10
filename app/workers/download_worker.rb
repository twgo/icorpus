require 'fileutils'

class DownloadWorker
  include Sidekiq::Worker
  sidekiq_options retry: false
  DOCS_PATH = File.join(Rails.root, 'public', 'download')

  def perform(*args)
    puts 'perform'
    url = Video.last.url
    get_corpus(url)
    puts '/perform'
  end

  def get_corpus(url)
    puts 'get_corpus'
    params = {data_formats: ['mp4', 'opus'], url: url}
    download_data(params)
    puts 'get_corpus/'
  end

  def download_data(params={})
    puts 'download_data'
    url = params[:url]
    data_formats = params[:data_formats]

    data_formats.each do |data_format|
      options = case data_format
      when 'opus'
        {
        'extract-audio': true,
        'audio-format': data_format,
        'audio-quality': 0,
        }
      when 'mp4'
        {
          'write-sub': true,
          'format': data_format,
        }
      end
      data = YoutubeDL.download url, options
      params = params.merge(data: data, data_format: data_format)
      move_files(params)
      log_data(data)
    end
  end

  def move_files(params={})
    data = params[:data]
    data_format = params[:data_format]
    move_file(params)
    move_file({data: data, data_format: 'vtt'}) if data_format == 'mp4'

    Video.last.update(status: 'downloaded')
  end

 def	move_file(params={})
   data = params[:data]
   data_format = params[:data_format]

   data_filename = File.basename data.filename, (File.extname data.filename)
   dirname = File.dirname("#{DOCS_PATH}/#{data_format}/#{data.uploader_id}")
   unless File.directory?(dirname)
     FileUtils.mkdir_p(dirname)
   end

   uploadername = File.dirname("#{DOCS_PATH}/#{data_format}/#{data.uploader_id}/#{data.filename}")
   unless File.directory?(uploadername)
     FileUtils.mkdir_p(uploadername)
   end
   if data_format == 'vtt'
     FileUtils.mv("#{data_filename}.zh-TW.vtt", "#{DOCS_PATH}/#{data_format}/#{data.uploader_id}/#{data_filename}.zh-TW.vtt")
   else
     FileUtils.mv("#{data_filename}.#{data_format}", "#{DOCS_PATH}/#{data_format}/#{data.uploader_id}/#{data_filename}.#{data_format}")
   end
 end

  def log_data(data)
    Video.last.update(
      yid: data.id,
      title: data.title,
      thumbnail: data.thumbnail,
      description: data.description,
      duration: data.duration,
      filename: data.filename,
      uploader: data.uploader,
      uploader_id: data.uploader_id,
      upload_date: data.upload_date,
      abr: data.abr,
      acodec: data.acodec,
      view_count: data.view_count,
      like_count: data.like_count,
      dislike_count: data.dislike_count,
      average_rating: data.average_rating,
      age_limit: data.age_limit,
    )
    # Not all video has..
    # repost_count: data.repost_count,
    # comment_count: data.comment_count,
    # location: data.location,
    # autonumber: data.autonumber,
    # playlist: data.playlist,
    # playlist_id: data.playlist_id,
    # playlist_title: data.playlist_title,
    # playlist_uploader: data.playlist_uploader,
    # playlist_uploader_id:	data.playlist_uploader_id,
  end
end