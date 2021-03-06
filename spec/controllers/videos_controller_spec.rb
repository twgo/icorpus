require 'rails_helper'
RSpec.describe VideosController, type: :controller do
  before do
    @list_url = 'https://www.youtube.com/playlist?list=PLZiftgt33q3Oea2oVAErUDdtZy1gXO6Zi'
    Video.create(url: @list_url)
  end
  describe "GET #redownload" do
    it "returns a success response" do
      params = attributes_for(:video, url: @list_url)
      allow(DownloadWorker).to receive(:perform_async)
      get :redownload, params: {url: @list_url}
      expect(response).to redirect_to videos_path
    end
  end
  describe "GET #get_vtt" do
    it "returns a success response" do
      allow(subject).to receive(:send_file)
      get :get_vtt
      expect(response).to be_success
    end
  end
  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_success
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new
      expect(response).to be_success
    end
  end

  describe "POST #create" do
    it "returns a ParameterMissing response" do
      expect{ post(:create, {}) }.to raise_error ActionController::ParameterMissing
    end
    it "create video" do
      allow(DownloadWorker).to receive(:perform_async)
      params = attributes_for(:video)
      expect{post :create, params: {video: params}}.to change{Video.count}.by 1
    end
    it "not create video if url is empty" do
      params = attributes_for(:video, url:'')
      expect{post :create, params: {video: params}}.to change{Video.count}.by 0
    end
  end
end
